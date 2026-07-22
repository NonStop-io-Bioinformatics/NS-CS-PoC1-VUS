"""Report Management Service + read API (FastAPI).

Two jobs:
  1. Generation  -- aggregate Order + Case + Variant DBs into the Report DB
                    (auto back-fill on startup; on-demand (re)generation endpoints).
  2. Viewing     -- read-only API consumed by the React frontend.
"""
import os
from typing import Optional

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from app import aggregator, config, db, writer

app = FastAPI(title="Report Management Service", version="1.1.0")

# CORS so the React dev server / other origins can call the API directly.
# In the container the frontend reaches us via nginx proxy, so this is mainly
# for local `npm run dev`. Defaults to permissive for the POC.
_origins = [o.strip() for o in os.environ.get("CORS_ORIGINS", "*").split(",") if o.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


class GenerateRequest(BaseModel):
    case_id: Optional[str] = None


def _generate(only_case=None, skip_existing=True):
    """Generate reports for eligible cases. Returns list of new report_ids."""
    created = []
    with db.connect(config.ORDER_DB_DSN) as oc, \
         db.connect(config.CASE_DB_DSN) as cc, \
         db.connect(config.VARIANT_DB_DSN) as vc, \
         db.connect(config.REPORT_DB_DSN) as rc:
        for case in aggregator.eligible_cases(cc, only_case):
            if skip_existing and writer.current_report(rc, case["case_id"]) is not None:
                continue
            payload = aggregator.build_report(oc, cc, vc, case["case_id"])
            created.append(writer.create_version(rc, payload, actor=config.SERVICE_NAME))
    return created


def _case_id_for(rc, report_id):
    with rc.cursor() as cur:
        cur.execute("SELECT case_id FROM reports WHERE report_id=%s", (report_id,))
        row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="report not found")
    return row["case_id"]


@app.on_event("startup")
def _startup():
    for dsn, name in (
        (config.ORDER_DB_DSN, "order_db"),
        (config.CASE_DB_DSN, "case_db"),
        (config.VARIANT_DB_DSN, "variant_db"),
        (config.REPORT_DB_DSN, "report_db"),
    ):
        db.wait_for(dsn, name)
    db.wait_for_table(config.REPORT_DB_DSN, "reports")

    if config.AUTO_GENERATE:
        try:
            created = _generate()
            print(f"[startup] generated {len(created)} report(s): {created}", flush=True)
        except Exception as e:  # noqa: BLE001 - never crash the service on back-fill
            print(f"[startup] generate failed: {e}", flush=True)


# --------------------------------------------------------------------------- #
# Generation
# --------------------------------------------------------------------------- #
@app.get("/health")
def health():
    return {"status": "ok", "service": config.SERVICE_NAME}


@app.post("/reports/generate")
def generate(req: Optional[GenerateRequest] = None):
    """Generate reports for eligible cases lacking a current report (idempotent)."""
    only = req.case_id if req else None
    created = _generate(only_case=only, skip_existing=True)
    return {"generated": len(created), "report_ids": created}


@app.post("/reports/{case_id}/regenerate")
def regenerate(case_id: str):
    """Force a new (amended) version for a case, superseding its current report."""
    created = _generate(only_case=case_id, skip_existing=False)
    if not created:
        raise HTTPException(status_code=404, detail=f"case {case_id} not found or not eligible")
    return {"report_id": created[0]}


# --------------------------------------------------------------------------- #
# Viewing (read-only)
# --------------------------------------------------------------------------- #
@app.get("/stats")
def stats():
    with db.connect(config.REPORT_DB_DSN) as rc, rc.cursor() as cur:
        cur.execute("SELECT count(*) AS n FROM reports WHERE is_current")
        total = cur.fetchone()["n"]
        cur.execute(
            "SELECT overall_result, count(*) AS n FROM reports WHERE is_current GROUP BY overall_result"
        )
        by_result = {r["overall_result"]: r["n"] for r in cur.fetchall()}
        cur.execute(
            "SELECT panel_name AS panel, count(*) AS n FROM reports WHERE is_current "
            "GROUP BY panel_name ORDER BY n DESC, panel_name"
        )
        by_panel = cur.fetchall()
        cur.execute(
            "SELECT count(*) AS n FROM report_variants rv "
            "JOIN reports r ON r.report_id = rv.report_id WHERE r.is_current"
        )
        variants = cur.fetchone()["n"]
    return {
        "total_reports": total,
        "reported_variants": variants,
        "by_result": by_result,
        "by_panel": by_panel,
    }


@app.get("/reports")
def list_reports():
    with db.connect(config.REPORT_DB_DSN) as rc, rc.cursor() as cur:
        cur.execute(
            """SELECT r.report_id, r.case_id, r.patient_name, r.patient_mrn,
                      r.panel_name, r.test_name, r.overall_result, r.status,
                      r.version, r.reported_date,
                      (SELECT count(*) FROM report_variants rv WHERE rv.report_id = r.report_id) AS variant_count
               FROM reports r
               WHERE r.is_current
               ORDER BY r.reported_date DESC, r.report_id"""
        )
        return cur.fetchall()


@app.get("/reports/{report_id}")
def get_report(report_id: str):
    with db.connect(config.REPORT_DB_DSN) as rc, rc.cursor() as cur:
        cur.execute("SELECT * FROM reports WHERE report_id=%s", (report_id,))
        report = cur.fetchone()
        if not report:
            raise HTTPException(status_code=404, detail="report not found")
        cur.execute(
            "SELECT * FROM report_variants WHERE report_id=%s ORDER BY report_variant_id",
            (report_id,),
        )
        report["variants"] = cur.fetchall()
        return report


@app.get("/reports/{report_id}/history")
def report_history(report_id: str):
    """All versions for the case this report belongs to (amend chain)."""
    with db.connect(config.REPORT_DB_DSN) as rc:
        case_id = _case_id_for(rc, report_id)
        with rc.cursor() as cur:
            cur.execute(
                """SELECT report_id, version, status, is_current, superseded_by,
                          reported_date, generated_at
                   FROM reports WHERE case_id=%s ORDER BY version""",
                (case_id,),
            )
            return cur.fetchall()


@app.get("/reports/{report_id}/audit")
def report_audit(report_id: str):
    """Audit trail for the case this report belongs to."""
    with db.connect(config.REPORT_DB_DSN) as rc:
        case_id = _case_id_for(rc, report_id)
        with rc.cursor() as cur:
            cur.execute(
                """SELECT audit_id, report_id, action, actor, prev_version,
                          new_version, created_at, detail
                   FROM report_audit WHERE case_id=%s ORDER BY audit_id""",
                (case_id,),
            )
            return cur.fetchall()
