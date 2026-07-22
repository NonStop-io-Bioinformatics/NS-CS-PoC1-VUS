-- ============================================================
-- CASE DB   (owned by Tertiary Analysis -> "Results")
-- Per-case analysis output: called variants, QC metrics, file pointers.
--
-- order_id / accession_number / patient_id are LOGICAL references into
-- ORDER DB. These live in a separate database, so they are intentionally
-- NOT foreign-key enforced across databases.
-- ============================================================

CREATE TABLE cases (
    case_id          text PRIMARY KEY,
    order_id         text NOT NULL,              -- -> order_db.orders
    accession_number text,                       -- -> order_db.specimens
    patient_id       text,                       -- -> order_db.patients
    assay            text NOT NULL,
    reference_build  text NOT NULL DEFAULT 'GRCh38' CHECK (reference_build IN ('GRCh37','GRCh38')),
    pipeline_name    text,
    pipeline_version text,
    analysis_status  text NOT NULL DEFAULT 'complete'
        CHECK (analysis_status IN ('queued','running','complete','failed','signed_out')),
    analyzed_date    date,
    analyst_id       text
);

CREATE TABLE case_variants (
    case_variant_id bigserial PRIMARY KEY,
    case_id         text NOT NULL REFERENCES cases(case_id),
    gene_symbol     text NOT NULL,
    transcript      text,
    chrom           text NOT NULL,
    pos             integer NOT NULL,
    ref             text NOT NULL,
    alt             text NOT NULL,
    build           text NOT NULL DEFAULT 'GRCh38',
    hgvs_c          text,
    hgvs_p          text,
    consequence     text,
    zygosity        text CHECK (zygosity IN ('heterozygous','homozygous','hemizygous')),
    genotype        text,
    depth           integer,
    allele_fraction numeric(4,3),
    filter_status   text DEFAULT 'PASS',
    dbsnp_id        text
);

CREATE TABLE qc_metrics (
    case_id                text PRIMARY KEY REFERENCES cases(case_id),
    mean_target_coverage   numeric,
    pct_target_20x         numeric(5,2),
    pct_target_100x        numeric(5,2),
    contamination_estimate numeric(6,4),
    total_reads            bigint,
    ts_tv_ratio            numeric(4,2)
);

CREATE TABLE case_files (
    file_id   bigserial PRIMARY KEY,
    case_id   text NOT NULL REFERENCES cases(case_id),
    file_type text NOT NULL CHECK (file_type IN ('VCF','gVCF','BAM','CRAM','FASTQ','QC_REPORT')),
    file_path text NOT NULL,                     -- HPC / object-store path
    checksum  text
);

CREATE INDEX idx_case_variants_case  ON case_variants(case_id);
CREATE INDEX idx_case_variants_gene  ON case_variants(gene_symbol);
CREATE INDEX idx_case_variants_locus ON case_variants(chrom, pos, ref, alt, build);
CREATE INDEX idx_cases_order         ON cases(order_id);
CREATE INDEX idx_case_files_case     ON case_files(case_id);
