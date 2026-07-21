-- Synthetic seed data for VARIANT DB.
-- Loci match CASE DB.case_variants. Coordinates/HGVS are realistic in form
-- but illustrative -- this is a POC knowledge base, not a data-of-record copy.

INSERT INTO variants (variant_id, chrom, pos, ref, alt, build, gene_symbol, transcript, hgvs_c, hgvs_p, consequence) VALUES
    ('VAR000001','17',43093867,'A','G','GRCh38','BRCA1','NM_007294.4','c.5074A>G','p.Ser1692Gly','missense_variant'),
    ('VAR000002','13',32340300,'C','T','GRCh38','BRCA2','NM_000059.4','c.7480C>T','p.Arg2494Ter','stop_gained'),
    ('VAR000003','17',7674220,'C','T','GRCh38','TP53','NM_000546.6','c.818G>A','p.Arg273His','missense_variant'),
    ('VAR000004','3',37017529,'G','A','GRCh38','MLH1','NM_000249.4','c.1852G>A','p.Ala618Thr','missense_variant'),
    ('VAR000005','7',117559590,'CTCT','C','GRCh38','CFTR','NM_000492.4','c.1521_1523del','p.Phe508del','inframe_deletion'),
    ('VAR000006','11',47337960,'G','A','GRCh38','MYBPC3','NM_000256.3','c.1504C>T','p.Arg502Trp','missense_variant'),
    ('VAR000007','5',112839521,'C','T','GRCh38','APC','NM_000038.6','c.4479G>A','p.Thr1493%3D','synonymous_variant'),
    ('VAR000008','2',47476400,'AG','A','GRCh38','MSH2','NM_000251.3','c.1204del','p.Ile402fs','frameshift_variant');

-- Classifications. VAR000001 demonstrates amend-not-overwrite:
--   id 2 = original VUS (superseded), id 1 = current Likely pathogenic.
INSERT INTO internal_classifications
    (classification_id, variant_id, classification, acmg_criteria, evidence_summary, classified_by, approved_by, classification_date, review_status, version, superseded_by, is_current) VALUES
    (1,'VAR000001','Likely pathogenic', ARRAY['PM2','PP3','PS4_moderate'],'Reclassified 2026: additional internal cases and segregation data support pathogenicity; upgraded from VUS.','analyst_kpatel','dir_mchen','2026-02-20','approved',2,NULL,true),
    (2,'VAR000001','VUS', ARRAY['PM2','PP3'],'Initial classification: rare in gnomAD, in-silico predictors supportive, insufficient case-level evidence.','analyst_jlee','dir_mchen','2024-05-10','approved',1,1,false),
    (3,'VAR000002','Pathogenic', ARRAY['PVS1','PM2','PS4'],'Nonsense variant, predicted NMD; absent from population databases; multiple affected probands.','analyst_jlee','dir_mchen','2025-09-15','approved',1,NULL,true),
    (4,'VAR000003','Pathogenic', ARRAY['PS1','PM1','PM2','PP3'],'Well-established TP53 DNA-binding domain hotspot; concordant with expert-panel assertion.','analyst_kpatel','dir_mchen','2025-06-30','approved',1,NULL,true),
    (5,'VAR000004','VUS', ARRAY['PM2','PP3','BP1'],'Conflicting evidence: rare but present in controls; in-silico mixed. Insufficient for classification.','analyst_kpatel','dir_mchen','2026-01-18','approved',1,NULL,true),
    (6,'VAR000005','Pathogenic', ARRAY['PM1','PM3','PP4','PS3'],'CFTR p.Phe508del: canonical CF-causing variant, functionally validated, practice-guideline supported.','analyst_jlee','dir_mchen','2024-11-02','approved',1,NULL,true),
    (7,'VAR000006','Likely pathogenic', ARRAY['PS4_moderate','PM2','PP3'],'Recurrent MYBPC3 missense enriched in HCM cohorts; rare in population; in-silico supportive.','analyst_jlee','dir_mchen','2025-12-10','approved',1,NULL,true),
    (8,'VAR000007','Likely benign', ARRAY['BP4','BP7'],'Synonymous, no predicted splice impact, common in population.','analyst_kpatel','dir_mchen','2025-03-22','approved',1,NULL,true),
    (9,'VAR000008','Pathogenic', ARRAY['PVS1','PM2'],'Frameshift leading to premature termination; absent from population databases.','analyst_jlee','dir_mchen','2026-03-08','approved',1,NULL,true);

SELECT setval('internal_classifications_id_seq', 9, true);

INSERT INTO external_annotations
    (variant_id, source, source_accession, source_classification, review_status, source_data, source_version, retrieved_date) VALUES
    ('VAR000001','ClinVar','VCV000055646','Conflicting classifications of pathogenicity','criteria provided, conflicting classifications (1 star)','{"submitters":5,"lp_count":2,"vus_count":3}'::jsonb,'ClinVar 2026-06','2026-06-15'),
    ('VAR000001','dbSNP','rs80357064',NULL,NULL,'{}'::jsonb,'dbSNP b156','2026-06-15'),
    ('VAR000002','ClinVar','VCV000051063','Pathogenic','reviewed by expert panel (3 stars)','{"panel":"ENIGMA BRCA1/2"}'::jsonb,'ClinVar 2026-06','2026-06-15'),
    ('VAR000003','ClinVar','VCV000012366','Pathogenic','criteria provided, multiple submitters, no conflicts (2 stars)','{"submitters":9}'::jsonb,'ClinVar 2026-06','2026-06-15'),
    ('VAR000003','COSMIC','COSV52664569','pathogenic (hotspot)',NULL,'{"tissue":"multiple","count":1420}'::jsonb,'COSMIC v99','2026-05-20'),
    ('VAR000004','ClinVar','VCV000090988','Uncertain significance','criteria provided, single submitter (1 star)','{"submitters":1}'::jsonb,'ClinVar 2026-06','2026-06-15'),
    ('VAR000005','ClinVar','VCV000007105','Pathogenic','practice guideline (4 stars)','{"panel":"CFTR2"}'::jsonb,'ClinVar 2026-06','2026-06-15'),
    ('VAR000006','ClinVar','VCV000042013','Likely pathogenic','criteria provided, multiple submitters, no conflicts (2 stars)','{"submitters":4}'::jsonb,'ClinVar 2026-06','2026-06-15'),
    ('VAR000007','ClinVar','VCV000000411','Benign','criteria provided, multiple submitters, no conflicts (2 stars)','{"submitters":6}'::jsonb,'ClinVar 2026-06','2026-06-15'),
    ('VAR000008','ClinVar','VCV000090775','Pathogenic','criteria provided, multiple submitters, no conflicts (2 stars)','{"submitters":3}'::jsonb,'ClinVar 2026-06','2026-06-15');

INSERT INTO population_frequencies
    (variant_id, source, source_version, global_af, popmax_af, popmax_population, allele_count, allele_number) VALUES
    ('VAR000001','gnomAD','v4.1',0.0000329,0.0000810,'nfe',5,152000),
    ('VAR000002','gnomAD','v4.1',0.0,NULL,NULL,0,152300),
    ('VAR000003','gnomAD','v4.1',0.0000066,0.0000140,'nfe',1,151900),
    ('VAR000004','gnomAD','v4.1',0.0004120,0.0009300,'amr',63,152800),
    ('VAR000005','gnomAD','v4.1',0.0069800,0.0170000,'nfe',1062,152100),
    ('VAR000006','gnomAD','v4.1',0.0000197,0.0000450,'nfe',3,152400),
    ('VAR000007','gnomAD','v4.1',0.1187000,0.1520000,'afr',18100,152500),
    ('VAR000008','gnomAD','v4.1',0.0,NULL,NULL,0,152200);

INSERT INTO variant_case_observations (variant_id, case_id, zygosity, observed_date) VALUES
    ('VAR000001','CASE-2026-00001','heterozygous','2026-01-09'),
    ('VAR000001','CASE-2026-00002','heterozygous','2026-01-14'),
    ('VAR000001','CASE-2026-00007','heterozygous','2026-03-08'),
    ('VAR000002','CASE-2026-00003','heterozygous','2026-01-19'),
    ('VAR000003','CASE-2026-00001','heterozygous','2026-01-09'),
    ('VAR000003','CASE-2026-00008','heterozygous','2026-03-09'),
    ('VAR000004','CASE-2026-00004','heterozygous','2026-02-05'),
    ('VAR000005','CASE-2026-00006','heterozygous','2026-02-18'),
    ('VAR000006','CASE-2026-00005','heterozygous','2026-02-14'),
    ('VAR000006','CASE-2026-00009','heterozygous','2026-03-14'),
    ('VAR000007','CASE-2026-00004','heterozygous','2026-02-05'),
    ('VAR000008','CASE-2026-00007','heterozygous','2026-03-08');
