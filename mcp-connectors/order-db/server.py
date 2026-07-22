"""NS MCP Connector — Order DB (read-only).

Exposes the lab's LIMS/order data (patients, orders, providers, specimens) to
Claude Science. Patient identifiers are DE-IDENTIFIED at this boundary by default
(DEIDENTIFY=false to disable) — genomic/clinical context stays, direct
identifiers do not leave the lab.
"""
import os
from datetime import date, datetime
from decimal import Decimal

import psycopg
from psycopg.rows import dict_row
from mcp.server.fastmcp import FastMCP

DSN = os.environ.get("ORDER_DB_DSN", "postgresql://order_svc:order_pass@localhost:5433/order_db")
DEIDENTIFY = os.environ.get("DEIDENTIFY", "true").lower() in ("1", "true", "yes")

mcp = FastMCP("ns-order-db")


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


def _deid_patient(p):
    """Strip direct identifiers; keep a stable pseudonym + clinically useful fields."""
    if not p or not DEIDENTIFY:
        return p
    p = dict(p)
    dob = p.get("date_of_birth")
    p["first_name"] = "[REDACTED]"
    p["last_name"] = "[REDACTED]"
    p["mrn"] = "[REDACTED]"
    p["pseudonym"] = p.get("patient_id")
    if dob:
        p["date_of_birth"] = str(dob)[:4]  # generalize to birth year
    return p


@mcp.tool()
def get_patient(patient_id: str) -> dict:
    """Get a patient's demographics by patient_id (PHI de-identified by default)."""
    with _conn() as c, c.cursor() as cur:
        cur.execute("SELECT * FROM patients WHERE patient_id=%s", (patient_id,))
        row = cur.fetchone()
    if not row:
        return {"error": f"patient {patient_id} not found"}
    return _clean(_deid_patient(row))


@mcp.tool()
def get_order(order_id: str) -> dict:
    """Get a test order with its patient, ordering provider, test, and specimen context."""
    with _conn() as c, c.cursor() as cur:
        cur.execute("SELECT * FROM orders WHERE order_id=%s", (order_id,))
        order = cur.fetchone()
        if not order:
            return {"error": f"order {order_id} not found"}
        cur.execute("SELECT * FROM patients WHERE patient_id=%s", (order["patient_id"],))
        patient = cur.fetchone()
        cur.execute("SELECT * FROM providers WHERE provider_id=%s", (order["provider_id"],))
        provider = cur.fetchone()
        cur.execute("SELECT * FROM test_catalog WHERE test_code=%s", (order["test_code"],))
        test = cur.fetchone()
        cur.execute("SELECT * FROM specimens WHERE order_id=%s ORDER BY specimen_id", (order_id,))
        specimens = cur.fetchall()
    return _clean({
        "order": order,
        "patient": _deid_patient(patient),
        "provider": provider,
        "test": test,
        "specimens": specimens,
    })


@mcp.tool()
def find_orders_for_patient(patient_id: str) -> list:
    """List all test orders placed for a given patient."""
    with _conn() as c, c.cursor() as cur:
        cur.execute(
            "SELECT order_id, test_code, order_status, ordered_date, clinical_indication "
            "FROM orders WHERE patient_id=%s ORDER BY ordered_date DESC",
            (patient_id,),
        )
        return _clean(cur.fetchall())


@mcp.tool()
def list_orders(status: str = "", limit: int = 50) -> list:
    """List orders, optionally filtered by order_status (e.g. 'reported')."""
    with _conn() as c, c.cursor() as cur:
        if status:
            cur.execute(
                "SELECT order_id, patient_id, test_code, order_status, ordered_date "
                "FROM orders WHERE order_status=%s ORDER BY ordered_date DESC LIMIT %s",
                (status, limit),
            )
        else:
            cur.execute(
                "SELECT order_id, patient_id, test_code, order_status, ordered_date "
                "FROM orders ORDER BY ordered_date DESC LIMIT %s",
                (limit,),
            )
        return _clean(cur.fetchall())


if __name__ == "__main__":
    mcp.run()
