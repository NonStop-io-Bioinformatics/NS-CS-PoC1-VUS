-- Synthetic seed data for VARIANT DB (12 variants). Loci match CASE DB.
-- VAR000007 (ATM) is Mr. Dibbs' VUS -- the Happy Path reclassification target.
-- Coordinates/HGVS are realistic in form but illustrative (POC KB, not data of record).

INSERT INTO variants (variant_id, chrom, pos, ref, alt, build, gene_symbol, transcript, hgvs_c, hgvs_p, consequence) VALUES
    ('VAR000001','17',43093867,'A','G','GRCh38','BRCA1','NM_007294.4','c.5074A>G','p.Ser1692Gly','missense_variant'),
    ('VAR000002','17',7674220,'C','T','GRCh38','TP53','NM_000546.6','c.818G>A','p.Arg273His','missense_variant'),
    ('VAR000003','13',32340300,'C','T','GRCh38','BRCA2','NM_000059.4','c.7480C>T','p.Arg2494Ter','stop_gained'),
    ('VAR000004','3',37017529,'G','A','GRCh38','MLH1','NM_000249.4','c.1852G>A','p.Ala618Thr','missense_variant'),
    ('VAR000005','5',112839521,'C','T','GRCh38','APC','NM_000038.6','c.4479G>A','p.Thr1493%3D','synonymous_variant'),
    ('VAR000006','2',47476400,'AG','A','GRCh38','MSH2','NM_000251.3','c.1204del','p.Ile402fs','frameshift_variant'),
    ('VAR000007','11',108293999,'G','A','GRCh38','ATM','NM_000051.4','c.6067G>A','p.Gly2023Arg','missense_variant'),
    ('VAR000008','11',47337960,'G','A','GRCh38','MYBPC3','NM_000256.3','c.1504C>T','p.Arg502Trp','missense_variant'),
    ('VAR000009','7',117559590,'CTCT','C','GRCh38','CFTR','NM_000492.4','c.1521_1523del','p.Phe508del','inframe_deletion'),
    ('VAR000010','16',23629500,'C','T','GRCh38','PALB2','NM_024675.4','c.3113G>A','p.Trp1038Ter','stop_gained'),
    ('VAR000011','22',28695868,'A','G','GRCh38','CHEK2','NM_007194.4','c.470T>C','p.Ile157Thr','missense_variant'),
    ('VAR000012','2',47783000,'G','A','GRCh38','MSH6','NM_000179.3','c.116G>A','p.Gly39Glu','missense_variant');

-- Current internal classifications (one per variant, version 1).
INSERT INTO internal_classifications
    (variant_id, classification, acmg_criteria, evidence_summary, classified_by, approved_by, classification_date, review_status, version, is_current) VALUES
    ('VAR000001','Likely pathogenic', ARRAY['PM2','PP3','PS4_moderate'],'Rare in gnomAD; in-silico supportive; enriched in HBOC cases.','analyst_jlee','dir_mchen','2025-11-10','approved',1,true),
    ('VAR000002','Pathogenic', ARRAY['PS1','PM1','PM2','PP3'],'Well-established TP53 DNA-binding-domain hotspot; concordant with expert panel.','analyst_kpatel','dir_mchen','2025-06-30','approved',1,true),
    ('VAR000003','Pathogenic', ARRAY['PVS1','PM2','PS4'],'Nonsense variant, predicted NMD; absent from population databases; multiple probands.','analyst_jlee','dir_mchen','2025-09-15','approved',1,true),
    ('VAR000004','VUS', ARRAY['PM2','PP3','BP1'],'Conflicting evidence: rare but present in controls; in-silico mixed. Insufficient for classification.','analyst_kpatel','dir_mchen','2026-01-18','approved',1,true),
    ('VAR000005','Likely benign', ARRAY['BP4','BP7'],'Synonymous, no predicted splice impact, common in population.','analyst_kpatel','dir_mchen','2025-03-22','approved',1,true),
    ('VAR000006','Pathogenic', ARRAY['PVS1','PM2'],'Frameshift leading to premature termination; absent from population databases.','analyst_jlee','dir_mchen','2026-02-11','approved',1,true),
    ('VAR000007','VUS', ARRAY['PM2','PP3'],'ATM missense: rare in gnomAD and in-silico predictors supportive, but case-level and functional evidence are currently insufficient to classify as likely pathogenic.','analyst_kpatel','dir_mchen','2026-02-14','approved',1,true),
    ('VAR000008','Likely pathogenic', ARRAY['PS4_moderate','PM2','PP3'],'Recurrent MYBPC3 missense enriched in HCM cohorts; rare in population; in-silico supportive.','analyst_jlee','dir_mchen','2025-12-10','approved',1,true),
    ('VAR000009','Pathogenic', ARRAY['PM1','PM3','PP4','PS3'],'CFTR p.Phe508del: canonical CF-causing variant, functionally validated, practice-guideline supported.','analyst_jlee','dir_mchen','2024-11-02','approved',1,true),
    ('VAR000010','Pathogenic', ARRAY['PVS1','PM2','PP1'],'PALB2 nonsense; predicted NMD; segregates with breast cancer in family.','analyst_jlee','dir_mchen','2026-02-27','approved',1,true),
    ('VAR000011','VUS', ARRAY['PP3','BS1'],'CHEK2 low-penetrance missense; population frequency higher than expected for high penetrance. Uncertain.','analyst_kpatel','dir_mchen','2026-02-27','approved',1,true),
    ('VAR000012','Likely benign', ARRAY['BP4','BS1'],'MSH6 missense; relatively common, in-silico benign.','analyst_jlee','dir_mchen','2026-03-12','approved',1,true);

INSERT INTO external_annotations
    (variant_id, source, source_accession, source_classification, review_status, source_data, source_version, retrieved_date) VALUES
    ('VAR000001','ClinVar','VCV000055646','Likely pathogenic','criteria provided, multiple submitters, no conflicts (2 stars)','{"submitters":6}'::jsonb,'ClinVar 2026-06','2026-06-15'),
    ('VAR000002','ClinVar','VCV000012366','Pathogenic','criteria provided, multiple submitters, no conflicts (2 stars)','{"submitters":9}'::jsonb,'ClinVar 2026-06','2026-06-15'),
    ('VAR000002','COSMIC','COSV52664569','pathogenic (hotspot)',NULL,'{"tissue":"multiple","count":1420}'::jsonb,'COSMIC v99','2026-05-20'),
    ('VAR000003','ClinVar','VCV000051063','Pathogenic','reviewed by expert panel (3 stars)','{"panel":"ENIGMA BRCA1/2"}'::jsonb,'ClinVar 2026-06','2026-06-15'),
    ('VAR000004','ClinVar','VCV000090988','Uncertain significance','criteria provided, single submitter (1 star)','{"submitters":1}'::jsonb,'ClinVar 2026-06','2026-06-15'),
    ('VAR000005','ClinVar','VCV000000411','Benign','criteria provided, multiple submitters, no conflicts (2 stars)','{"submitters":6}'::jsonb,'ClinVar 2026-06','2026-06-15'),
    ('VAR000006','ClinVar','VCV000090775','Pathogenic','criteria provided, multiple submitters, no conflicts (2 stars)','{"submitters":3}'::jsonb,'ClinVar 2026-06','2026-06-15'),
    ('VAR000007','ClinVar','VCV000127436','Uncertain significance','criteria provided, multiple submitters, no conflicts (2 stars)','{"submitters":4,"lp_count":1,"vus_count":3}'::jsonb,'ClinVar 2026-06','2026-06-15'),
    ('VAR000007','dbSNP','rs587779843',NULL,NULL,'{}'::jsonb,'dbSNP b156','2026-06-15'),
    ('VAR000008','ClinVar','VCV000042013','Likely pathogenic','criteria provided, multiple submitters, no conflicts (2 stars)','{"submitters":4}'::jsonb,'ClinVar 2026-06','2026-06-15'),
    ('VAR000009','ClinVar','VCV000007105','Pathogenic','practice guideline (4 stars)','{"panel":"CFTR2"}'::jsonb,'ClinVar 2026-06','2026-06-15'),
    ('VAR000010','ClinVar','VCV000128076','Pathogenic','criteria provided, multiple submitters, no conflicts (2 stars)','{"submitters":5}'::jsonb,'ClinVar 2026-06','2026-06-15'),
    ('VAR000011','ClinVar','VCV000128042','Conflicting classifications of pathogenicity','criteria provided, conflicting classifications (1 star)','{"submitters":8,"benign":3,"vus":3,"lp":2}'::jsonb,'ClinVar 2026-06','2026-06-15'),
    ('VAR000012','ClinVar','VCV000089560','Likely benign','criteria provided, multiple submitters, no conflicts (2 stars)','{"submitters":5}'::jsonb,'ClinVar 2026-06','2026-06-15');

INSERT INTO population_frequencies
    (variant_id, source, source_version, global_af, popmax_af, popmax_population, allele_count, allele_number) VALUES
    ('VAR000001','gnomAD','v4.1',0.0000329,0.0000810,'nfe',5,152000),
    ('VAR000002','gnomAD','v4.1',0.0000066,0.0000140,'nfe',1,151900),
    ('VAR000003','gnomAD','v4.1',0.0,NULL,NULL,0,152300),
    ('VAR000004','gnomAD','v4.1',0.0004120,0.0009300,'amr',63,152800),
    ('VAR000005','gnomAD','v4.1',0.1187000,0.1520000,'afr',18100,152500),
    ('VAR000006','gnomAD','v4.1',0.0,NULL,NULL,0,152200),
    ('VAR000007','gnomAD','v4.1',0.0000132,0.0000280,'nfe',2,151800),
    ('VAR000008','gnomAD','v4.1',0.0000197,0.0000450,'nfe',3,152400),
    ('VAR000009','gnomAD','v4.1',0.0069800,0.0170000,'nfe',1062,152100),
    ('VAR000010','gnomAD','v4.1',0.0,NULL,NULL,0,152000),
    ('VAR000011','gnomAD','v4.1',0.0031000,0.0045000,'nfe',472,152300),
    ('VAR000012','gnomAD','v4.1',0.0089000,0.0121000,'sas',1355,152200);

INSERT INTO variant_case_observations (variant_id, case_id, zygosity, observed_date) VALUES
    ('VAR000001','CASE-2026-00001','heterozygous','2026-01-09'),
    ('VAR000001','CASE-2026-00003','heterozygous','2026-01-19'),
    ('VAR000002','CASE-2026-00001','heterozygous','2026-01-09'),
    ('VAR000002','CASE-2026-00011','heterozygous','2026-03-09'),
    ('VAR000003','CASE-2026-00002','heterozygous','2026-01-14'),
    ('VAR000003','CASE-2026-00011','heterozygous','2026-03-09'),
    ('VAR000004','CASE-2026-00004','heterozygous','2026-02-05'),
    ('VAR000005','CASE-2026-00004','heterozygous','2026-02-05'),
    ('VAR000006','CASE-2026-00005','heterozygous','2026-02-11'),
    ('VAR000007','CASE-2026-00005','heterozygous','2026-02-11'),
    ('VAR000007','CASE-2026-00011','heterozygous','2026-03-09'),
    ('VAR000008','CASE-2026-00006','heterozygous','2026-02-14'),
    ('VAR000008','CASE-2026-00007','heterozygous','2026-02-18'),
    ('VAR000009','CASE-2026-00008','heterozygous','2026-02-21'),
    ('VAR000010','CASE-2026-00009','heterozygous','2026-02-27'),
    ('VAR000011','CASE-2026-00009','heterozygous','2026-02-27'),
    ('VAR000012','CASE-2026-00012','heterozygous','2026-03-12');
