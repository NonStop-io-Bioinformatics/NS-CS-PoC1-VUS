"""Runtime configuration, from environment (with docker-network defaults)."""
import os

ORDER_DB_DSN   = os.environ.get("ORDER_DB_DSN",   "postgresql://order_svc:order_pass@order-db:5432/order_db")
CASE_DB_DSN    = os.environ.get("CASE_DB_DSN",    "postgresql://case_svc:case_pass@case-db:5432/case_db")
VARIANT_DB_DSN = os.environ.get("VARIANT_DB_DSN", "postgresql://variant_svc:variant_pass@variant-db:5432/variant_db")
REPORT_DB_DSN  = os.environ.get("REPORT_DB_DSN",  "postgresql://report_svc:report_pass@report-db:5432/report_db")

AUTO_GENERATE  = os.environ.get("AUTO_GENERATE", "true").lower() in ("1", "true", "yes")
SERVICE_NAME   = "report-management-service"

# A case is eligible for a report once tertiary analysis is done.
ELIGIBLE_STATUSES = ("complete", "signed_out")
