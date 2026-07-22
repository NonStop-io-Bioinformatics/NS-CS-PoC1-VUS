-- ============================================================
-- REPORT DB   (produced by the Report Management Service)
-- Signed-out patient reports = the aggregate of Order + Case + Variant.
--
-- This is the store the NS MCP Connector reads/writes. It is a
-- self-contained SNAPSHOT: patient identifiers are denormalized in at
-- generation time, which makes this the most PHI-dense store in the POC
-- -- exactly why de-identification is enforced at the connector boundary.
--
-- Reports are versioned amend-not-overwrite (like the KB classifications):
-- a re-issue inserts a new is_current row and supersedes the prior one.
-- ============================================================

CREATE TABLE reports (
    report_id         text PRIMARY KEY,          -- e.g. RPT-2026-00001-v1
    case_id           text NOT NULL,             -- logical -> case_db.cases
    order_id          text NOT NULL,             -- logical -> order_db.orders
    accession_number  text,

    -- patient snapshot (denormalized from ORDER DB at generation time) => PHI
    patient_id        text,
    patient_mrn       text,
    patient_name      text,
    patient_dob       date,
    patient_sex       text,

    -- clinical / order context
    ordering_provider text,
    clinic_name       text,
    test_name         text,
    panel_name        text,
    indication        text,
    icd10_codes       text[],
    hpo_terms         text[],

    -- result
    reference_build   text,
    overall_result    text,                      -- Positive / Negative / Uncertain
    result_summary    text,

    -- lifecycle (amend-not-overwrite)
    status            text NOT NULL DEFAULT 'final'
        CHECK (status IN ('draft','final','amended','superseded')),
    version           integer NOT NULL DEFAULT 1,
    superseded_by     text REFERENCES reports(report_id),
    is_current        boolean NOT NULL DEFAULT true,

    -- sign-off
    analyst_id        text,
    director_id       text,
    reported_date     date,

    -- provenance: source data versions used to build this report
    provenance        jsonb,
    generated_at      timestamptz NOT NULL DEFAULT now(),
    generated_by      text NOT NULL DEFAULT 'report-management-service'
);

CREATE TABLE report_variants (
    report_variant_id     bigserial PRIMARY KEY,
    report_id             text NOT NULL REFERENCES reports(report_id) ON DELETE CASCADE,
    variant_id            text,                  -- logical -> variant_db (KB id, if matched)
    gene_symbol           text,
    transcript            text,
    chrom                 text,
    pos                   integer,
    ref                   text,
    alt                   text,
    build                 text,
    hgvs_c                text,
    hgvs_p                text,
    consequence           text,
    zygosity              text,
    classification        text,                  -- current internal KB classification
    acmg_criteria         text[],
    clinvar_significance  text,
    clinvar_review_status text,
    gnomad_af             numeric,
    internal_case_count   integer,
    interpretation        text                   -- templated narrative
);

-- Every write (service generation and, later, connector writes) is logged here.
CREATE TABLE report_audit (
    audit_id     bigserial PRIMARY KEY,
    report_id    text,
    case_id      text,
    action       text NOT NULL,                  -- generate / amend / update / finalize
    actor        text NOT NULL,                  -- service name or analyst_id
    prev_version integer,
    new_version  integer,
    detail       jsonb,
    created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_reports_case        ON reports(case_id);
CREATE INDEX idx_reports_current     ON reports(case_id) WHERE is_current;
CREATE INDEX idx_reports_result      ON reports(overall_result);
CREATE INDEX idx_rv_report           ON report_variants(report_id);
CREATE INDEX idx_rv_gene             ON report_variants(gene_symbol);
CREATE INDEX idx_rv_locus            ON report_variants(chrom, pos, ref, alt, build);
CREATE INDEX idx_rv_classification   ON report_variants(classification);
CREATE INDEX idx_audit_report        ON report_audit(report_id);
