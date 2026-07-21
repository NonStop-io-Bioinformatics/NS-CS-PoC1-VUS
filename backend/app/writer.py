"""Write reports into the Report DB with amend-not-overwrite versioning + audit."""
from psycopg.types.json import Jsonb

_REPORT_COLS = """
    report_id, case_id, order_id, accession_number,
    patient_id, patient_mrn, patient_name, patient_dob, patient_sex,
    ordering_provider, clinic_name, test_name, panel_name, indication, icd10_codes, hpo_terms,
    reference_build, overall_result, result_summary, status, version, is_current,
    analyst_id, director_id, reported_date, provenance, generated_by
"""

_REPORT_VALS = """
    %(report_id)s, %(case_id)s, %(order_id)s, %(accession_number)s,
    %(patient_id)s, %(patient_mrn)s, %(patient_name)s, %(patient_dob)s, %(patient_sex)s,
    %(ordering_provider)s, %(clinic_name)s, %(test_name)s, %(panel_name)s, %(indication)s, %(icd10_codes)s, %(hpo_terms)s,
    %(reference_build)s, %(overall_result)s, %(result_summary)s, %(status)s, %(version)s, true,
    %(analyst_id)s, %(director_id)s, %(reported_date)s, %(provenance)s, %(generated_by)s
"""


def current_report(report_conn, case_id):
    with report_conn.cursor() as cur:
        cur.execute(
            "SELECT report_id, version FROM reports WHERE case_id=%s AND is_current",
            (case_id,),
        )
        return cur.fetchone()


def create_version(report_conn, payload, actor):
    """Insert the next version of a report for a case, superseding the current one.

    Runs as a single transaction: insert new (is_current) report + variants,
    supersede the prior current report, and write an audit row.
    Returns the new report_id.
    """
    case_id = payload["case_id"]
    with report_conn.cursor() as cur:
        cur.execute(
            "SELECT report_id, version FROM reports WHERE case_id=%s AND is_current FOR UPDATE",
            (case_id,),
        )
        prev = cur.fetchone()
        prev_version = prev["version"] if prev else 0
        new_version = prev_version + 1
        report_id = f"RPT-{case_id.replace('CASE-', '')}-v{new_version}"
        action = "generate" if prev_version == 0 else "amend"
        status = "final" if prev_version == 0 else "amended"

        params = {
            **payload,
            "report_id": report_id,
            "status": status,
            "version": new_version,
            "provenance": Jsonb(payload["provenance"]),
            "generated_by": actor,
        }
        cur.execute(f"INSERT INTO reports ({_REPORT_COLS}) VALUES ({_REPORT_VALS})", params)

        for rv in payload["variants"]:
            cur.execute(
                """INSERT INTO report_variants
                     (report_id, variant_id, gene_symbol, transcript, chrom, pos, ref, alt, build,
                      hgvs_c, hgvs_p, consequence, zygosity, classification, acmg_criteria,
                      clinvar_significance, clinvar_review_status, gnomad_af, internal_case_count, interpretation)
                   VALUES
                     (%(report_id)s, %(variant_id)s, %(gene_symbol)s, %(transcript)s, %(chrom)s, %(pos)s, %(ref)s, %(alt)s, %(build)s,
                      %(hgvs_c)s, %(hgvs_p)s, %(consequence)s, %(zygosity)s, %(classification)s, %(acmg_criteria)s,
                      %(clinvar_significance)s, %(clinvar_review_status)s, %(gnomad_af)s, %(internal_case_count)s, %(interpretation)s)""",
                {**rv, "report_id": report_id},
            )

        if prev:
            cur.execute(
                "UPDATE reports SET is_current=false, status='superseded', superseded_by=%s WHERE report_id=%s",
                (report_id, prev["report_id"]),
            )

        cur.execute(
            """INSERT INTO report_audit (report_id, case_id, action, actor, prev_version, new_version, detail)
               VALUES (%s, %s, %s, %s, %s, %s, %s)""",
            (report_id, case_id, action, actor, prev_version or None, new_version,
             Jsonb({"variant_count": len(payload["variants"])})),
        )

    report_conn.commit()
    return report_id
