-- Synthetic seed data for CASE DB. Loci are consistent with VARIANT DB.

INSERT INTO cases
    (case_id, order_id, accession_number, patient_id, assay, reference_build, pipeline_name, pipeline_version, analysis_status, analyzed_date, analyst_id) VALUES
    ('CASE-2026-00001','ORD-2026-00001','ACC-2026-0001','PT000001','Hereditary Cancer Panel','GRCh38','NS-Germline-Pipeline','v3.2.1','signed_out','2026-01-09','analyst_jlee'),
    ('CASE-2026-00002','ORD-2026-00002','ACC-2026-0002','PT000003','Hereditary Cancer Panel','GRCh38','NS-Germline-Pipeline','v3.2.1','signed_out','2026-01-14','analyst_jlee'),
    ('CASE-2026-00003','ORD-2026-00003','ACC-2026-0003','PT000002','Hereditary Cancer Panel','GRCh38','NS-Germline-Pipeline','v3.2.1','signed_out','2026-01-19','analyst_kpatel'),
    ('CASE-2026-00004','ORD-2026-00004','ACC-2026-0004','PT000006','Lynch Syndrome Panel','GRCh38','NS-Germline-Pipeline','v3.2.1','signed_out','2026-02-05','analyst_kpatel'),
    ('CASE-2026-00005','ORD-2026-00005','ACC-2026-0005','PT000002','Cardiomyopathy Panel','GRCh38','NS-Germline-Pipeline','v3.2.1','signed_out','2026-02-14','analyst_jlee'),
    ('CASE-2026-00006','ORD-2026-00006','ACC-2026-0006','PT000004','CFTR Full Gene Analysis','GRCh38','NS-Germline-Pipeline','v3.2.1','signed_out','2026-02-18','analyst_kpatel'),
    ('CASE-2026-00007','ORD-2026-00007','ACC-2026-0007','PT000005','Whole Exome Sequencing','GRCh38','NS-Exome-Pipeline','v4.0.0','complete','2026-03-08','analyst_jlee'),
    ('CASE-2026-00008','ORD-2026-00008','ACC-2026-0008','PT000004','Hereditary Cancer Panel','GRCh38','NS-Germline-Pipeline','v3.2.1','signed_out','2026-03-09','analyst_kpatel'),
    ('CASE-2026-00009','ORD-2026-00009','ACC-2026-0009','PT000006','Cardiomyopathy Panel','GRCh38','NS-Germline-Pipeline','v3.2.1','complete','2026-03-14','analyst_jlee'),
    ('CASE-2026-00010','ORD-2026-00010','ACC-2026-0010','PT000004','Whole Exome Sequencing','GRCh38','NS-Exome-Pipeline','v4.0.0','running',NULL,'analyst_jlee');

INSERT INTO case_variants
    (case_id, gene_symbol, transcript, chrom, pos, ref, alt, build, hgvs_c, hgvs_p, consequence, zygosity, genotype, depth, allele_fraction, filter_status, dbsnp_id) VALUES
    -- CASE 1: BRCA1 (VAR001) + TP53 (VAR003)
    ('CASE-2026-00001','BRCA1','NM_007294.4','17',43093867,'A','G','GRCh38','c.5074A>G','p.Ser1692Gly','missense_variant','heterozygous','0/1',120,0.480,'PASS','rs80357064'),
    ('CASE-2026-00001','TP53','NM_000546.6','17',7674220,'C','T','GRCh38','c.818G>A','p.Arg273His','missense_variant','heterozygous','0/1',95,0.510,'PASS','rs28934576'),
    -- CASE 2: BRCA1 (VAR001) recurrence
    ('CASE-2026-00002','BRCA1','NM_007294.4','17',43093867,'A','G','GRCh38','c.5074A>G','p.Ser1692Gly','missense_variant','heterozygous','0/1',110,0.490,'PASS','rs80357064'),
    -- CASE 3: BRCA2 (VAR002)
    ('CASE-2026-00003','BRCA2','NM_000059.4','13',32340300,'C','T','GRCh38','c.7480C>T','p.Arg2494Ter','stop_gained','heterozygous','0/1',130,0.470,'PASS',NULL),
    -- CASE 4: MLH1 (VAR004) + APC (VAR007, benign)
    ('CASE-2026-00004','MLH1','NM_000249.4','3',37017529,'G','A','GRCh38','c.1852G>A','p.Ala618Thr','missense_variant','heterozygous','0/1',100,0.500,'PASS',NULL),
    ('CASE-2026-00004','APC','NM_000038.6','5',112839521,'C','T','GRCh38','c.4479G>A','p.Thr1493%3D','synonymous_variant','heterozygous','0/1',88,0.520,'PASS','rs2229992'),
    -- CASE 5: MYBPC3 (VAR006)
    ('CASE-2026-00005','MYBPC3','NM_000256.3','11',47337960,'G','A','GRCh38','c.1504C>T','p.Arg502Trp','missense_variant','heterozygous','0/1',140,0.460,'PASS','rs375882485'),
    -- CASE 6: CFTR (VAR005) F508del
    ('CASE-2026-00006','CFTR','NM_000492.4','7',117559590,'CTCT','C','GRCh38','c.1521_1523del','p.Phe508del','inframe_deletion','heterozygous','0/1',115,0.450,'PASS','rs113993960'),
    -- CASE 7: MSH2 (VAR008) + BRCA1 (VAR001) recurrence
    ('CASE-2026-00007','MSH2','NM_000251.3','2',47476400,'AG','A','GRCh38','c.1204del','p.Ile402fs','frameshift_variant','heterozygous','0/1',105,0.490,'PASS',NULL),
    ('CASE-2026-00007','BRCA1','NM_007294.4','17',43093867,'A','G','GRCh38','c.5074A>G','p.Ser1692Gly','missense_variant','heterozygous','0/1',98,0.500,'PASS','rs80357064'),
    -- CASE 8: TP53 (VAR003) recurrence
    ('CASE-2026-00008','TP53','NM_000546.6','17',7674220,'C','T','GRCh38','c.818G>A','p.Arg273His','missense_variant','heterozygous','0/1',125,0.520,'PASS','rs28934576'),
    -- CASE 9: MYBPC3 (VAR006) recurrence
    ('CASE-2026-00009','MYBPC3','NM_000256.3','11',47337960,'G','A','GRCh38','c.1504C>T','p.Arg502Trp','missense_variant','heterozygous','0/1',133,0.480,'PASS','rs375882485');
    -- CASE 10: analysis still running -> no variants yet

INSERT INTO qc_metrics
    (case_id, mean_target_coverage, pct_target_20x, pct_target_100x, contamination_estimate, total_reads, ts_tv_ratio) VALUES
    ('CASE-2026-00001',185.4,99.80,96.20,0.0021,68000000,2.05),
    ('CASE-2026-00002',172.1,99.70,94.80,0.0034,61000000,2.03),
    ('CASE-2026-00003',190.6,99.85,97.10,0.0012,72000000,2.06),
    ('CASE-2026-00004',168.9,99.60,93.50,0.0045,59000000,2.02),
    ('CASE-2026-00005',201.3,99.90,98.00,0.0009,80000000,2.07),
    ('CASE-2026-00006',158.2,99.40,91.20,0.0051,55000000,2.01),
    ('CASE-2026-00007',110.7,98.90,82.40,0.0067,140000000,2.00),
    ('CASE-2026-00008',177.5,99.75,95.60,0.0028,64000000,2.04),
    ('CASE-2026-00009',195.0,99.88,97.50,0.0015,78000000,2.06);

INSERT INTO case_files (case_id, file_type, file_path, checksum) VALUES
    ('CASE-2026-00001','VCF','/hpc/lab/cases/CASE-2026-00001/CASE-2026-00001.vcf.gz','md5:a1b2c3d4e5f60001'),
    ('CASE-2026-00001','BAM','/hpc/lab/cases/CASE-2026-00001/CASE-2026-00001.bam','md5:a1b2c3d4e5f60002'),
    ('CASE-2026-00002','VCF','/hpc/lab/cases/CASE-2026-00002/CASE-2026-00002.vcf.gz','md5:a1b2c3d4e5f60003'),
    ('CASE-2026-00003','VCF','/hpc/lab/cases/CASE-2026-00003/CASE-2026-00003.vcf.gz','md5:a1b2c3d4e5f60004'),
    ('CASE-2026-00004','VCF','/hpc/lab/cases/CASE-2026-00004/CASE-2026-00004.vcf.gz','md5:a1b2c3d4e5f60005'),
    ('CASE-2026-00005','VCF','/hpc/lab/cases/CASE-2026-00005/CASE-2026-00005.vcf.gz','md5:a1b2c3d4e5f60006'),
    ('CASE-2026-00006','VCF','/hpc/lab/cases/CASE-2026-00006/CASE-2026-00006.vcf.gz','md5:a1b2c3d4e5f60007'),
    ('CASE-2026-00007','VCF','/hpc/lab/cases/CASE-2026-00007/CASE-2026-00007.vcf.gz','md5:a1b2c3d4e5f60008'),
    ('CASE-2026-00007','CRAM','/hpc/lab/cases/CASE-2026-00007/CASE-2026-00007.cram','md5:a1b2c3d4e5f60009'),
    ('CASE-2026-00008','VCF','/hpc/lab/cases/CASE-2026-00008/CASE-2026-00008.vcf.gz','md5:a1b2c3d4e5f60010'),
    ('CASE-2026-00009','VCF','/hpc/lab/cases/CASE-2026-00009/CASE-2026-00009.vcf.gz','md5:a1b2c3d4e5f60011');
