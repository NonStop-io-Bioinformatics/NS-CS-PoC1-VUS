"""NS MCP Connector — Case DB (read-only).

Exposes tertiary-analysis output (called variants, QC, file pointers) to Claude
Science. No direct patient identifiers live here (only a patient_id token).
Also exposes each case as an importable MCP *resource* (`case://<case_id>`).
"""
import json
import os
from datetime import date, datetime
from decimal import Decimal

import psycopg
from psycopg.rows import dict_row
from mcp.server.fastmcp import FastMCP

DSN = os.environ.get("CASE_DB_DSN", "postgresql://case_svc:case_pass@localhost:5434/case_db")

mcp = FastMCP("ns-case-db")


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


def _case_dossier(case_id):
    with _conn() as c, c.cursor() as cur:
        cur.execute("SELECT * FROM cases WHERE case_id=%s", (case_id,))
        case = cur.fetchone()
        if not case:
            return None
        cur.execute("SELECT * FROM case_variants WHERE case_id=%s ORDER BY case_variant_id", (case_id,))
        variants = cur.fetchall()
        cur.execute("SELECT * FROM qc_metrics WHERE case_id=%s", (case_id,))
        qc = cur.fetchone()
        cur.execute("SELECT * FROM case_files WHERE case_id=%s ORDER BY file_id", (case_id,))
        files = cur.fetchall()
    return _clean({"case": case, "variants": variants, "qc_metrics": qc, "files": files})


@mcp.tool()
def get_case(case_id: str) -> dict:
    """Get a case: metadata, called variants, QC metrics, and analysis file pointers."""
    dossier = _case_dossier(case_id)
    return dossier if dossier else {"error": f"case {case_id} not found"}


@mcp.tool()
def get_case_variants(case_id: str) -> list:
    """List the variants called in a case (gene, HGVS, zygosity, depth, VAF)."""
    with _conn() as c, c.cursor() as cur:
        cur.execute("SELECT * FROM case_variants WHERE case_id=%s ORDER BY case_variant_id", (case_id,))
        return _clean(cur.fetchall())


@mcp.tool()
def find_cases_by_gene(gene_symbol: str) -> list:
    """Find cases that have a called variant in a given gene."""
    with _conn() as c, c.cursor() as cur:
        cur.execute(
            "SELECT DISTINCT case_id, gene_symbol, hgvs_c, hgvs_p FROM case_variants "
            "WHERE gene_symbol=%s ORDER BY case_id",
            (gene_symbol,),
        )
        return _clean(cur.fetchall())


@mcp.tool()
def find_cases_by_variant(chrom: str, pos: int, ref: str, alt: str, build: str = "GRCh38") -> list:
    """Find every case in which a specific variant (by locus) was observed."""
    with _conn() as c, c.cursor() as cur:
        cur.execute(
            "SELECT case_id, gene_symbol, hgvs_c, zygosity, allele_fraction FROM case_variants "
            "WHERE chrom=%s AND pos=%s AND ref=%s AND alt=%s AND build=%s ORDER BY case_id",
            (chrom, pos, ref, alt, build),
        )
        return _clean(cur.fetchall())


@mcp.resource("case://{case_id}")
def case_resource(case_id: str) -> str:
    """Importable case dossier (JSON) for a given case_id."""
    dossier = _case_dossier(case_id)
    return json.dumps(dossier or {"error": f"case {case_id} not found"}, indent=2)


if __name__ == "__main__":
    mcp.run()
