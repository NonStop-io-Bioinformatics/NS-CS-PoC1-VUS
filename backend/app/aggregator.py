"""Core aggregation: turn a case (Order + Case + Variant DBs) into a report payload.

Deterministic, no LLM. The Report Management Service assembles the structured
evidence; the Claude Science layer is where interpretive reasoning happens later.
"""
from app import config

# Higher rank = more clinically significant; drives the overall result.
_RANK = {
    "Pathogenic": 4,
    "Likely pathogenic": 3,
    "VUS": 2,
    "Likely benign": 1,
    "Benign": 0,
}


def eligible_cases(case_conn, only_case=None):
    with case_conn.cursor() as cur:
        if only_case:
            cur.execute("SELECT * FROM cases WHERE case_id = %s", (only_case,))
        else:
            cur.execute(
                "SELECT * FROM cases WHERE analysis_status = ANY(%s) ORDER BY case_id",
                (list(config.ELIGIBLE_STATUSES),),
            )
        return cur.fetchall()


def _lookup_kb(variant_conn, cv, kb_meta):
    """Enrich a called variant with internal KB + external annotations."""
    out = {}
    with variant_conn.cursor() as cur:
        cur.execute(
            "SELECT * FROM variants WHERE chrom=%s AND pos=%s AND ref=%s AND alt=%s AND build=%s",
            (cv["chrom"], cv["pos"], cv["ref"], cv["alt"], cv["build"]),
        )
        v = cur.fetchone()
        if not v:
            return out
        vid = v["variant_id"]
        out["variant_id"] = vid

        cur.execute(
            "SELECT * FROM internal_classifications WHERE variant_id=%s AND is_current",
            (vid,),
        )
        cls = cur.fetchone()
        if cls:
            out["classification"] = cls["classification"]
            out["acmg_criteria"] = cls["acmg_criteria"]
            kb_meta["classification_dates"][vid] = cls["classification_date"].isoformat()

        cur.execute(
            "SELECT * FROM external_annotations WHERE variant_id=%s AND source='ClinVar' "
            "ORDER BY annotation_id LIMIT 1",
            (vid,),
        )
        clinvar = cur.fetchone()
        if clinvar:
            out["clinvar_significance"] = clinvar["source_classification"]
            out["clinvar_review_status"] = clinvar["review_status"]
            if clinvar["source_version"]:
                kb_meta["clinvar_versions"].add(clinvar["source_version"])

        cur.execute(
            "SELECT * FROM population_frequencies WHERE variant_id=%s ORDER BY freq_id LIMIT 1",
            (vid,),
        )
        freq = cur.fetchone()
        if freq:
            out["gnomad_af"] = freq["global_af"]
            if freq["source_version"]:
                kb_meta["gnomad_versions"].add(f"gnomAD {freq['source_version']}")

        cur.execute(
            "SELECT count(*) AS n FROM variant_case_observations WHERE variant_id=%s",
            (vid,),
        )
        out["internal_case_count"] = cur.fetchone()["n"]
    return out


def _interpret(rv):
    cls = rv.get("classification") or "not previously classified in the internal knowledge base"
    parts = [
        f"A {rv['zygosity']} {rv['consequence']} in {rv['gene_symbol']} "
        f"({rv['hgvs_c']}, {rv['hgvs_p']}) was identified and classified as {cls}."
    ]
    if rv.get("clinvar_significance"):
        parts.append(
            f"ClinVar: '{rv['clinvar_significance']}' ({rv['clinvar_review_status']})."
        )
    if rv.get("gnomad_af") is not None:
        parts.append(f"gnomAD global allele frequency {rv['gnomad_af']}.")
    if rv.get("internal_case_count"):
        parts.append(f"Observed in {rv['internal_case_count']} prior internal case(s).")
    if rv.get("acmg_criteria"):
        parts.append(f"ACMG criteria applied: {', '.join(rv['acmg_criteria'])}.")
    return " ".join(parts)


def _overall(variants):
    ranks = [_RANK.get(v.get("classification"), -1) for v in variants]
    top = max(ranks) if ranks else -1
    if top >= 3:
        return "Positive", "Reportable pathogenic / likely pathogenic variant(s) identified."
    if top == 2:
        return "Uncertain", "Variant(s) of uncertain significance identified; no pathogenic variant detected."
    return "Negative", "No reportable pathogenic or likely pathogenic variant identified."


def build_report(order_conn, case_conn, variant_conn, case_id):
    """Assemble a full report payload dict (including nested 'variants')."""
    with case_conn.cursor() as cur:
        cur.execute("SELECT * FROM cases WHERE case_id=%s", (case_id,))
        case = cur.fetchone()
        if not case:
            raise ValueError(f"case {case_id} not found")
        cur.execute(
            "SELECT * FROM case_variants WHERE case_id=%s ORDER BY case_variant_id",
            (case_id,),
        )
        called = cur.fetchall()

    order = patient = provider = test = None
    with order_conn.cursor() as cur:
        cur.execute("SELECT * FROM orders WHERE order_id=%s", (case["order_id"],))
        order = cur.fetchone()
        if order:
            cur.execute("SELECT * FROM patients WHERE patient_id=%s", (order["patient_id"],))
            patient = cur.fetchone()
            cur.execute("SELECT * FROM providers WHERE provider_id=%s", (order["provider_id"],))
            provider = cur.fetchone()
            cur.execute("SELECT * FROM test_catalog WHERE test_code=%s", (order["test_code"],))
            test = cur.fetchone()

    kb_meta = {"clinvar_versions": set(), "gnomad_versions": set(), "classification_dates": {}}
    report_variants = []
    for cv in called:
        kb = _lookup_kb(variant_conn, cv, kb_meta)
        rv = {
            "variant_id": kb.get("variant_id"),
            "gene_symbol": cv["gene_symbol"],
            "transcript": cv["transcript"],
            "chrom": cv["chrom"], "pos": cv["pos"], "ref": cv["ref"], "alt": cv["alt"], "build": cv["build"],
            "hgvs_c": cv["hgvs_c"], "hgvs_p": cv["hgvs_p"], "consequence": cv["consequence"],
            "zygosity": cv["zygosity"],
            "classification": kb.get("classification"),
            "acmg_criteria": kb.get("acmg_criteria"),
            "clinvar_significance": kb.get("clinvar_significance"),
            "clinvar_review_status": kb.get("clinvar_review_status"),
            "gnomad_af": kb.get("gnomad_af"),
            "internal_case_count": kb.get("internal_case_count", 0),
        }
        rv["interpretation"] = _interpret(rv)
        report_variants.append(rv)

    result, summary = _overall(report_variants)

    provenance = {
        "source_case_id": case_id,
        "order_id": case["order_id"],
        "pipeline_name": case["pipeline_name"],
        "pipeline_version": case["pipeline_version"],
        "reference_build": case["reference_build"],
        "clinvar_versions": sorted(kb_meta["clinvar_versions"]),
        "gnomad_versions": sorted(kb_meta["gnomad_versions"]),
        "kb_classification_dates": kb_meta["classification_dates"],
        "source_databases": ["order_db", "case_db", "variant_db"],
    }

    return {
        "case_id": case_id,
        "order_id": case["order_id"],
        "accession_number": case["accession_number"],
        "patient_id": order["patient_id"] if order else case.get("patient_id"),
        "patient_mrn": patient["mrn"] if patient else None,
        "patient_name": f"{patient['first_name']} {patient['last_name']}" if patient else None,
        "patient_dob": patient["date_of_birth"] if patient else None,
        "patient_sex": patient["sex"] if patient else None,
        "ordering_provider": f"Dr. {provider['first_name']} {provider['last_name']}" if provider else None,
        "clinic_name": provider["clinic_name"] if provider else None,
        "test_name": test["test_name"] if test else case["assay"],
        "panel_name": test["panel_name"] if test else None,
        "indication": order["clinical_indication"] if order else None,
        "icd10_codes": order["icd10_codes"] if order else None,
        "hpo_terms": order["hpo_terms"] if order else None,
        "reference_build": case["reference_build"],
        "overall_result": result,
        "result_summary": summary,
        "analyst_id": case["analyst_id"],
        "director_id": "dir_mchen",
        "reported_date": case["analyzed_date"],
        "provenance": provenance,
        "variants": report_variants,
    }
