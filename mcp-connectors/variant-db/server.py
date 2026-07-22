"""NS MCP Connector — Variant DB / Knowledge Base (read + gated write).

The research substrate: prior internal classifications (versioned), cached
ClinVar/dbSNP/COSMIC/gnomAD annotations, and internal case precedent.

WRITE: `submit_classification` is a hard-gated clinical write. It uses a
confirm-gate — the first call (confirm=false) returns a PREVIEW including how
many other internal cases the reclassification would affect; only confirm=true
commits, as a NEW version that supersedes the current one (history preserved).
"""
import os
from datetime import date, datetime
from decimal import Decimal

import psycopg
from psycopg.rows import dict_row
from mcp.server.fastmcp import FastMCP

DSN = os.environ.get("VARIANT_DB_DSN", "postgresql://variant_svc:variant_pass@localhost:5435/variant_db")

VALID_CLASSES = {"Pathogenic", "Likely pathogenic", "VUS", "Likely benign", "Benign"}

mcp = FastMCP("ns-variant-db")


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


@mcp.tool()
def lookup_variant(chrom: str, pos: int, ref: str, alt: str, build: str = "GRCh38") -> dict:
    """Look up a variant in the internal KB by genomic locus.

    Returns the canonical record, current internal classification + ACMG criteria,
    number of prior classification versions, cached ClinVar/dbSNP/COSMIC and gnomAD
    annotations, and the internal case precedent count.
    """
    with _conn() as c, c.cursor() as cur:
        cur.execute(
            "SELECT * FROM variants WHERE chrom=%s AND pos=%s AND ref=%s AND alt=%s AND build=%s",
            (chrom, pos, ref, alt, build),
        )
        v = cur.fetchone()
        if not v:
            return {"found": False, "locus": f"{chrom}:{pos} {ref}>{alt} ({build})"}
        vid = v["variant_id"]
        cur.execute("SELECT * FROM internal_classifications WHERE variant_id=%s AND is_current", (vid,))
        current = cur.fetchone()
        cur.execute("SELECT count(*) AS n FROM internal_classifications WHERE variant_id=%s", (vid,))
        versions = cur.fetchone()["n"]
        cur.execute("SELECT * FROM external_annotations WHERE variant_id=%s ORDER BY annotation_id", (vid,))
        external = cur.fetchall()
        cur.execute("SELECT * FROM population_frequencies WHERE variant_id=%s ORDER BY freq_id", (vid,))
        freq = cur.fetchall()
        cur.execute("SELECT count(*) AS n FROM variant_case_observations WHERE variant_id=%s", (vid,))
        precedent = cur.fetchone()["n"]
    return _clean({
        "found": True,
        "variant": v,
        "current_classification": current,
        "classification_versions": versions,
        "external_annotations": external,
        "population_frequencies": freq,
        "internal_case_precedent": precedent,
    })


@mcp.tool()
def search_variants_by_gene(gene_symbol: str) -> list:
    """List KB variants in a gene with their current classification."""
    with _conn() as c, c.cursor() as cur:
        cur.execute(
            """SELECT v.variant_id, v.chrom, v.pos, v.ref, v.alt, v.hgvs_c, v.hgvs_p,
                      ic.classification
               FROM variants v
               LEFT JOIN internal_classifications ic
                    ON ic.variant_id = v.variant_id AND ic.is_current
               WHERE v.gene_symbol=%s
               ORDER BY v.pos""",
            (gene_symbol,),
        )
        return _clean(cur.fetchall())


@mcp.tool()
def get_classification_history(variant_id: str) -> list:
    """Full classification version history for a variant (amend-not-overwrite chain)."""
    with _conn() as c, c.cursor() as cur:
        cur.execute(
            """SELECT classification_id, classification, acmg_criteria, evidence_summary,
                      classified_by, approved_by, classification_date, version,
                      is_current, superseded_by
               FROM internal_classifications WHERE variant_id=%s ORDER BY version""",
            (variant_id,),
        )
        return _clean(cur.fetchall())


@mcp.tool()
def get_variant_precedent(variant_id: str) -> dict:
    """Which internal cases have observed this variant (reanalysis / impact view)."""
    with _conn() as c, c.cursor() as cur:
        cur.execute(
            "SELECT case_id, zygosity, observed_date FROM variant_case_observations "
            "WHERE variant_id=%s ORDER BY observed_date",
            (variant_id,),
        )
        cases = cur.fetchall()
    return _clean({"variant_id": variant_id, "case_count": len(cases), "cases": cases})


@mcp.tool()
def submit_classification(
    variant_id: str,
    classification: str,
    acmg_criteria: list[str],
    evidence_summary: str,
    classified_by: str,
    approved_by: str = "",
    confirm: bool = False,
) -> dict:
    """Reclassify a variant in the internal KB (GATED clinical write).

    Call FIRST with confirm=false to get a preview: the current vs proposed
    classification and how many other internal cases would be affected. Call again
    with confirm=true to commit — this inserts a NEW current version and supersedes
    the previous one (never overwrites; the history is retained).
    """
    if classification not in VALID_CLASSES:
        return {"error": f"classification must be one of {sorted(VALID_CLASSES)}"}

    with _conn() as c, c.cursor() as cur:
        cur.execute("SELECT * FROM variants WHERE variant_id=%s", (variant_id,))
        v = cur.fetchone()
        if not v:
            return {"error": f"variant {variant_id} not found"}
        cur.execute("SELECT * FROM internal_classifications WHERE variant_id=%s AND is_current", (variant_id,))
        current = cur.fetchone()
        cur.execute("SELECT count(*) AS n FROM variant_case_observations WHERE variant_id=%s", (variant_id,))
        affected = cur.fetchone()["n"]

        if not confirm:
            return _clean({
                "preview": True,
                "committed": False,
                "variant": {k: v[k] for k in ("variant_id", "gene_symbol", "hgvs_c", "hgvs_p")},
                "current_classification": current["classification"] if current else None,
                "proposed_classification": classification,
                "proposed_acmg_criteria": acmg_criteria,
                "affected_internal_cases": affected,
                "note": "Re-call with confirm=true to commit. A new version will supersede "
                        "the current classification; the previous version is retained.",
            })

        prev_version = current["version"] if current else 0
        new_version = prev_version + 1
        cur.execute(
            """INSERT INTO internal_classifications
                 (variant_id, classification, acmg_criteria, evidence_summary,
                  classified_by, approved_by, classification_date, review_status,
                  version, is_current)
               VALUES (%s, %s, %s, %s, %s, %s, CURRENT_DATE, 'approved', %s, true)
               RETURNING classification_id""",
            (variant_id, classification, acmg_criteria, evidence_summary,
             classified_by, approved_by or None, new_version),
        )
        new_id = cur.fetchone()["classification_id"]
        if current:
            cur.execute(
                "UPDATE internal_classifications SET is_current=false, superseded_by=%s "
                "WHERE classification_id=%s",
                (new_id, current["classification_id"]),
            )
        c.commit()

    return _clean({
        "preview": False,
        "committed": True,
        "variant_id": variant_id,
        "new_classification_id": new_id,
        "version": new_version,
        "previous_version": prev_version,
        "previous_classification": current["classification"] if current else None,
        "new_classification": classification,
        "affected_internal_cases": affected,
    })


if __name__ == "__main__":
    mcp.run()
