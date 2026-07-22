Actor: Scientist (From the Genomics Lab)

Order DB   : test orders, patients, providers (what LIMS/OpenELIS produces)
Case DB    : the variants called from sequencing + QC metrics (analysis results)
Variant DB : the lab's internal knowledge base: variant classifications, ClinVar/gnomAD annotations, prior case observations


1. Patient Report Received -> Contains VUS (Variants of Uncertain Significance).
2. Scientist imports patient, case & variant data from OrderDB, CaseDB and VariantDB using their connectors.
3. Scientist does research and comes to a conclusion.
4. Scientist updates the Report DB and creates a new updated report. It stores both, the original lab version of the report and the updated report backed by research with Claude Science.