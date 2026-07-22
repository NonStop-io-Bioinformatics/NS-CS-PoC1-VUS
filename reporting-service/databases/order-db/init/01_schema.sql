-- ============================================================
-- ORDER DB   (owned by LIMS / OpenELIS -> "Order Info")
-- Test orders, patients, ordering providers, specimens.
--
-- This is an inside-the-lab operational store and therefore holds
-- (synthetic) PHI. De-identification is enforced downstream at the
-- NS MCP Connector boundary -- NOT in this database.
-- ============================================================

CREATE TABLE patients (
    patient_id    text PRIMARY KEY,
    mrn           text UNIQUE NOT NULL,           -- medical record number
    first_name    text NOT NULL,
    last_name     text NOT NULL,
    date_of_birth date NOT NULL,
    sex           text NOT NULL CHECK (sex IN ('F','M','U')),
    ethnicity     text,
    created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE providers (
    provider_id text PRIMARY KEY,
    npi         text UNIQUE,
    first_name  text NOT NULL,
    last_name   text NOT NULL,
    clinic_name text,
    specialty   text
);

CREATE TABLE test_catalog (
    test_code   text PRIMARY KEY,
    test_name   text NOT NULL,
    panel_name  text,
    methodology text,                            -- 'NGS Panel','WES','WGS'
    gene_count  integer
);

CREATE TABLE orders (
    order_id            text PRIMARY KEY,
    patient_id          text NOT NULL REFERENCES patients(patient_id),
    provider_id         text NOT NULL REFERENCES providers(provider_id),
    test_code           text NOT NULL REFERENCES test_catalog(test_code),
    priority            text NOT NULL DEFAULT 'routine' CHECK (priority IN ('routine','stat')),
    clinical_indication text,
    icd10_codes         text[],
    hpo_terms           text[],                  -- phenotype (Human Phenotype Ontology)
    order_status        text NOT NULL DEFAULT 'ordered'
        CHECK (order_status IN ('ordered','collected','received','in_progress','resulted','reported')),
    ordered_date        date NOT NULL,
    received_date       date
);

CREATE TABLE specimens (
    specimen_id         text PRIMARY KEY,
    order_id            text NOT NULL REFERENCES orders(order_id),
    accession_number    text UNIQUE NOT NULL,
    specimen_type       text NOT NULL,           -- 'blood','saliva','FFPE tissue'
    collection_datetime timestamptz,
    received_datetime   timestamptz
);

CREATE INDEX idx_orders_patient   ON orders(patient_id);
CREATE INDEX idx_orders_status    ON orders(order_status);
CREATE INDEX idx_orders_test      ON orders(test_code);
CREATE INDEX idx_specimens_order  ON specimens(order_id);
