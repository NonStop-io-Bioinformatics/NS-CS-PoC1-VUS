-- Synthetic seed data for ORDER DB (12 patients). No real patient data.
-- Patient PT000011 = "John Dibbs" (Mr. Dibbs) — the Happy Path demo case.

INSERT INTO patients (patient_id, mrn, first_name, last_name, date_of_birth, sex, ethnicity) VALUES
    ('PT000001','MRN1001','Jane','Doe','1975-03-12','F','European'),
    ('PT000002','MRN1002','John','Smith','1968-07-22','M','European'),
    ('PT000003','MRN1003','Maria','Garcia','1982-11-05','F','Latino/Admixed American'),
    ('PT000004','MRN1004','Robert','Johnson','1990-01-30','M','African/African American'),
    ('PT000005','MRN1005','Linda','Nguyen','2015-06-18','F','East Asian'),
    ('PT000006','MRN1006','David','Brown','1955-09-09','M','European'),
    ('PT000007','MRN1007','Emily','Clark','1979-04-25','F','European'),
    ('PT000008','MRN1008','Ahmed','Khan','1988-12-14','M','South Asian'),
    ('PT000009','MRN1009','Sofia','Rossi','1972-08-03','F','European'),
    ('PT000010','MRN1010','Wei','Chen','2018-02-20','M','East Asian'),
    ('PT000011','MRN1011','John','Dibbs','1963-05-17','M','European'),
    ('PT000012','MRN1012','Grace','Miller','1985-10-11','F','African/African American');

INSERT INTO providers (provider_id, npi, first_name, last_name, clinic_name, specialty) VALUES
    ('PRV001','1234567890','Alice','Carter','Hope Cancer Center','Oncology'),
    ('PRV002','2345678901','Ben','Lewis','Heart Institute','Cardiology'),
    ('PRV003','3456789012','Carol','Reed','Regional Genetics Clinic','Medical Genetics'),
    ('PRV004','4567890123','Dan','Price','GI Associates','Gastroenterology'),
    ('PRV005','5678901234','Eva','Novak','Coastal Oncology','Oncology');

INSERT INTO test_catalog (test_code, test_name, panel_name, methodology, gene_count) VALUES
    ('HCP-01','Hereditary Cancer Panel','Hereditary Cancer','NGS Panel',84),
    ('CARD-01','Cardiomyopathy Panel','Cardiomyopathy','NGS Panel',121),
    ('WES-01','Whole Exome Sequencing','Exome','WES',20000),
    ('CFTR-01','CFTR Full Gene Analysis','Cystic Fibrosis','NGS Panel',1),
    ('LYNCH-01','Lynch Syndrome Panel','Lynch / Colorectal','NGS Panel',7);

INSERT INTO orders
    (order_id, patient_id, provider_id, test_code, priority, clinical_indication, icd10_codes, hpo_terms, order_status, ordered_date, received_date) VALUES
    ('ORD-2026-00001','PT000001','PRV001','HCP-01','routine','Personal hx breast cancer, dx age 38', ARRAY['C50.9','Z80.3'], ARRAY['HP:0003002'], 'reported','2026-01-05','2026-01-07'),
    ('ORD-2026-00002','PT000002','PRV003','HCP-01','routine','Family hx pancreatic cancer', ARRAY['Z80.8'], ARRAY['HP:0002894'], 'reported','2026-01-10','2026-01-12'),
    ('ORD-2026-00003','PT000003','PRV001','HCP-01','routine','Family hx breast/ovarian cancer', ARRAY['Z80.3','Z80.41'], ARRAY['HP:0003002','HP:0100615'], 'reported','2026-01-15','2026-01-17'),
    ('ORD-2026-00004','PT000004','PRV004','LYNCH-01','routine','Early-onset colorectal cancer', ARRAY['C18.9','Z80.0'], ARRAY['HP:0003003'], 'reported','2026-02-01','2026-02-03'),
    ('ORD-2026-00005','PT000005','PRV003','WES-01','stat','Global developmental delay, dysmorphic features', ARRAY['R62.50','Q87.1'], ARRAY['HP:0001263','HP:0001999'], 'reported','2026-02-05','2026-02-08'),
    ('ORD-2026-00006','PT000006','PRV002','CARD-01','routine','Hypertrophic cardiomyopathy, family hx SCD', ARRAY['I42.1','Z82.41'], ARRAY['HP:0001639'], 'reported','2026-02-10','2026-02-12'),
    ('ORD-2026-00007','PT000007','PRV002','CARD-01','routine','HCM cascade testing', ARRAY['I42.1'], ARRAY['HP:0001639'], 'reported','2026-02-14','2026-02-16'),
    ('ORD-2026-00008','PT000008','PRV003','CFTR-01','routine','CF carrier screening, reproductive', ARRAY['Z31.430'], ARRAY[]::text[], 'reported','2026-02-18','2026-02-19'),
    ('ORD-2026-00009','PT000009','PRV001','HCP-01','routine','Bilateral breast cancer, family hx', ARRAY['C50.9','Z80.3'], ARRAY['HP:0003002'], 'reported','2026-02-22','2026-02-24'),
    ('ORD-2026-00010','PT000010','PRV003','WES-01','routine','Unexplained multisystem disorder', ARRAY['R68.89'], ARRAY['HP:0001939'], 'in_progress','2026-03-01','2026-03-03'),
    ('ORD-2026-00011','PT000011','PRV001','HCP-01','routine','Personal hx colorectal + family hx multiple cancers (Li-Fraumeni eval)', ARRAY['C18.9','Z80.9'], ARRAY['HP:0006752','HP:0100242'], 'reported','2026-03-04','2026-03-06'),
    ('ORD-2026-00012','PT000012','PRV004','LYNCH-01','routine','Family hx colorectal cancer, screening', ARRAY['Z80.0'], ARRAY['HP:0003003'], 'reported','2026-03-08','2026-03-10');

INSERT INTO specimens
    (specimen_id, order_id, accession_number, specimen_type, collection_datetime, received_datetime) VALUES
    ('SPC-0001','ORD-2026-00001','ACC-2026-0001','blood',   '2026-01-05 09:10+00','2026-01-07 11:00+00'),
    ('SPC-0002','ORD-2026-00002','ACC-2026-0002','saliva',  '2026-01-10 08:30+00','2026-01-12 10:15+00'),
    ('SPC-0003','ORD-2026-00003','ACC-2026-0003','blood',   '2026-01-15 14:00+00','2026-01-17 09:40+00'),
    ('SPC-0004','ORD-2026-00004','ACC-2026-0004','blood',   '2026-02-01 10:05+00','2026-02-03 08:50+00'),
    ('SPC-0005','ORD-2026-00005','ACC-2026-0005','blood',   '2026-02-05 07:55+00','2026-02-08 12:10+00'),
    ('SPC-0006','ORD-2026-00006','ACC-2026-0006','blood',   '2026-02-10 11:20+00','2026-02-12 09:00+00'),
    ('SPC-0007','ORD-2026-00007','ACC-2026-0007','blood',   '2026-02-14 10:30+00','2026-02-16 09:20+00'),
    ('SPC-0008','ORD-2026-00008','ACC-2026-0008','saliva',  '2026-02-18 13:45+00','2026-02-19 10:30+00'),
    ('SPC-0009','ORD-2026-00009','ACC-2026-0009','blood',   '2026-02-22 09:15+00','2026-02-24 11:05+00'),
    ('SPC-0010','ORD-2026-00010','ACC-2026-0010','blood',   '2026-03-01 08:15+00','2026-03-03 09:30+00'),
    ('SPC-0011','ORD-2026-00011','ACC-2026-0011','blood',   '2026-03-04 10:40+00','2026-03-06 09:50+00'),
    ('SPC-0012','ORD-2026-00012','ACC-2026-0012','blood',   '2026-03-08 09:00+00','2026-03-10 10:00+00');
