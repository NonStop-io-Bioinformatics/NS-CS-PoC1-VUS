"""NS MCP Connector — Report DB (read + de-id + gated write).

The entry point: signed-out patient reports. Patient identifiers are
DE-IDENTIFIED at this boundary by default. Reports are the most PHI-dense store,
so this connector is where the PHI gate matters most.

WRITE: `flag_report_for_reanalysis` is a gated, non-destructive write (it records
a reanalysis request in the audit log) — deliberately NOT a raw edit of a
finalized clinical report. Actual report re-issue goes through the Report
Management Service (regeneration), not this connector.
Also exposes each report as an importable MCP *resource* (`report://<report_id>`).
"""
import json
import os
from datetime import date, datetime
from decimal import Decimal

import psycopg
from psycopg.rows import dict_row
from psycopg.types.json import Jsonb
from mcp.server.fastmcp import FastMCP

DSN = os.environ.get("REPORT_DB_DSN", "postgresql://report_svc:report_pass@localhost:5436/report_db")
DEIDENTIFY = os.environ.get("DEIDENTIFY", "true").lower() in ("1", "true", "yes")

mcp = FastMCP("ns-report-db")


def _conn():
    return psycopg.connect(DSN, row_factory=dict_row)


def _clean(obj):
    if isinstance(obj, dict):
        return {k: _clean(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_clean(v) for v in obj]
    if isinstance(obj, (date, datetime)):
        return obj.isoformat()
    if isinstance(obj, Decimal):
        return float(obj)
    return obj


def _deid_report(r):
    if not r or not DEIDENTIFY:
        return r
    r = dict(r)
    r["pseudonym"] = r.get("patient_id")
    r["patient_name"] = "[REDACTED]"
    r["patient_mrn"] = "[REDACTED]"
    if r.get("patient_dob"):
        r["patient_dob"] = str(r["patient_dob"])[:4]  # birth year only
    return r


def _report_full(report_id):
    with _conn() as c, c.cursor() as cur:
        cur.execute("SELECT * FROM reports WHERE report_id=%s", (report_id,))
        report = cur.fetchone()
        if not report:
            return None
        cur.execute(
            "SELECT * FROM report_variants WHERE report_id=%s ORDER BY report_variant_id",
            (report_id,),
        )
        report = _deid_report(report)
        report["variants"] = cur.fetchall()
    return _clean(report)


@mcp.tool()
def list_reports(overall_result: str = "", limit: int = 50) -> list:
    """List current reports, optionally filtered by overall_result (Positive/Uncertain/Negative)."""
    with _conn() as c, c.cursor() as cur:
        if overall_result:
            cur.execute(
                """SELECT report_id, case_id, patient_id, patient_name, panel_name,
                          overall_result, version, reported_date
                   FROM reports WHERE is_current AND overall_result=%s
                   ORDER BY reported_date DESC LIMIT %s""",
                (overall_result, limit),
            )
        else:
            cur.execute(
                """SELECT report_id, case_id, patient_id, patient_name, panel_name,
                          overall_result, version, reported_date
                   FROM reports WHERE is_current
                   ORDER BY reported_date DESC LIMIT %s""",
                (limit,),
            )
        rows = [_deid_report(r) for r in cur.fetchall()]
        return _clean(rows)


@mcp.tool()
def get_report(report_id: str) -> dict:
    """Get a full report: patient snapshot (de-identified), variants, provenance."""
    report = _report_full(report_id)
    return report if report else {"error": f"report {report_id} not found"}


@mcp.tool()
def search_reports_by_gene(gene_symbol: str) -> list:
    """Find current reports that include a reported variant in a given gene."""
    with _conn() as c, c.cursor() as cur:
        cur.execute(
            """SELECT DISTINCT r.report_id, r.case_id, r.patient_id, r.overall_result,
                      rv.gene_symbol, rv.hgvs_c, rv.classification
               FROM reports r
               JOIN report_variants rv ON rv.report_id = r.report_id
               WHERE r.is_current AND rv.gene_symbol=%s
               ORDER BY r.report_id""",
            (gene_symbol,),
        )
        return _clean(cur.fetchall())


@mcp.tool()
def get_report_history(report_id: str) -> list:
    """All versions of the report for this report's case (amend chain)."""
    with _conn() as c, c.cursor() as cur:
        cur.execute("SELECT case_id FROM reports WHERE report_id=%s", (report_id,))
        row = cur.fetchone()
        if not row:
            return [{"error": f"report {report_id} not found"}]
        cur.execute(
            """SELECT report_id, version, status, is_current, superseded_by, reported_date
               FROM reports WHERE case_id=%s ORDER BY version""",
            (row["case_id"],),
        )
        return _clean(cur.fetchall())


@mcp.tool()
def flag_report_for_reanalysis(report_id: str, reason: str, requested_by: str, confirm: bool = False) -> dict:
    """Flag a report for reanalysis (GATED, non-destructive write to the audit log).

    Use after a variant reclassification that may affect this report. Call first
    with confirm=false for a preview; confirm=true records the flag. This does NOT
    edit the finalized report — re-issue happens via the Report Management Service.
    """
    with _conn() as c, c.cursor() as cur:
        cur.execute("SELECT report_id, case_id, is_current FROM reports WHERE report_id=%s", (report_id,))
        r = cur.fetchone()
        if not r:
            return {"error": f"report {report_id} not found"}
        if not confirm:
            return {
                "preview": True,
                "committed": False,
                "report_id": report_id,
                "case_id": r["case_id"],
                "reason": reason,
                "note": "Re-call with confirm=true to record the reanalysis flag in the audit log.",
            }
        cur.execute(
            """INSERT INTO report_audit (report_id, case_id, action, actor, detail)
               VALUES (%s, %s, 'reanalysis_flagged', %s, %s)
               RETURNING audit_id""",
            (report_id, r["case_id"], requested_by, Jsonb({"reason": reason})),
        )
        audit_id = cur.fetchone()["audit_id"]
        c.commit()
    return {"preview": False, "committed": True, "report_id": report_id, "audit_id": audit_id}


@mcp.resource("report://{report_id}")
def report_resource(report_id: str) -> str:
    """Importable report (JSON, de-identified) for a given report_id."""
    report = _report_full(report_id)
    return json.dumps(report or {"error": f"report {report_id} not found"}, indent=2)


if __name__ == "__main__":
    mcp.run()
