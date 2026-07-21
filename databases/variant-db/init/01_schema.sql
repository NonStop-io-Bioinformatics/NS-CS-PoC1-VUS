-- ============================================================
-- VARIANT DB   (owned by Knowledge Base; fed by ClinVar/dbSNP/COSMIC)
-- The lab's internal variant knowledge base:
--   * canonical (normalized) variant records
--   * the lab's own classifications -- versioned, amend-not-overwrite
--   * external annotations (ClinVar / dbSNP / COSMIC / gnomAD)
--   * population frequencies
--   * internal case-observation counts (logical link to CASE DB)
-- ============================================================

CREATE TABLE variants (
    variant_id  text PRIMARY KEY,
    chrom       text NOT NULL,
    pos         integer NOT NULL,
    ref         text NOT NULL,
    alt         text NOT NULL,
    build       text NOT NULL DEFAULT 'GRCh38' CHECK (build IN ('GRCh37','GRCh38')),
    gene_symbol text,
    transcript  text,
    hgvs_c      text,
    hgvs_p      text,
    consequence text,
    UNIQUE (chrom, pos, ref, alt, build)         -- canonical normalized locus key
);

-- Versioned classifications. A re-classification INSERTs a new current row
-- and points the prior row's superseded_by at it -- the history is never
-- overwritten. Exactly one is_current = true row is expected per variant.
CREATE TABLE internal_classifications (
    classification_id   bigint PRIMARY KEY,
    variant_id          text NOT NULL REFERENCES variants(variant_id),
    classification      text NOT NULL CHECK (classification IN
        ('Pathogenic','Likely pathogenic','VUS','Likely benign','Benign')),
    acmg_criteria       text[],                  -- e.g. {PVS1,PM2,PP3}
    evidence_summary    text,
    classified_by       text,
    approved_by         text,
    classification_date date NOT NULL,
    review_status       text NOT NULL DEFAULT 'approved'
        CHECK (review_status IN ('draft','reviewed','approved')),
    version             integer NOT NULL DEFAULT 1,
    superseded_by       bigint REFERENCES internal_classifications(classification_id),
    is_current          boolean NOT NULL DEFAULT true
);
CREATE SEQUENCE internal_classifications_id_seq OWNED BY internal_classifications.classification_id;
ALTER TABLE internal_classifications ALTER COLUMN classification_id SET DEFAULT nextval('internal_classifications_id_seq');

CREATE TABLE external_annotations (
    annotation_id         bigserial PRIMARY KEY,
    variant_id            text NOT NULL REFERENCES variants(variant_id),
    source                text NOT NULL CHECK (source IN ('ClinVar','dbSNP','COSMIC','gnomAD')),
    source_accession      text,                  -- VCV..., rs..., COSV...
    source_classification text,                  -- e.g. ClinVar clinical significance
    review_status         text,                  -- e.g. ClinVar review status / star level
    source_data           jsonb,
    source_version        text,                  -- e.g. 'ClinVar 2026-06'
    retrieved_date        date
);

CREATE TABLE population_frequencies (
    freq_id           bigserial PRIMARY KEY,
    variant_id        text NOT NULL REFERENCES variants(variant_id),
    source            text NOT NULL DEFAULT 'gnomAD',
    source_version    text,                      -- e.g. 'v4.1'
    global_af         numeric,
    popmax_af         numeric,
    popmax_population text,
    allele_count      bigint,
    allele_number     bigint
);

CREATE TABLE variant_case_observations (
    observation_id bigserial PRIMARY KEY,
    variant_id     text NOT NULL REFERENCES variants(variant_id),
    case_id        text NOT NULL,                -- logical ref -> case_db.cases
    zygosity       text,
    observed_date  date
);

CREATE INDEX idx_variants_locus   ON variants(chrom, pos, ref, alt, build);
CREATE INDEX idx_variants_gene    ON variants(gene_symbol);
CREATE INDEX idx_class_variant    ON internal_classifications(variant_id);
CREATE INDEX idx_class_current    ON internal_classifications(variant_id) WHERE is_current;
CREATE INDEX idx_extann_variant   ON external_annotations(variant_id);
CREATE INDEX idx_popfreq_variant  ON population_frequencies(variant_id);
CREATE INDEX idx_obs_variant      ON variant_case_observations(variant_id);
