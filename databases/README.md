# Lab databases + Report Management Service — NS_CS_PoC1

The lab side of the POC diagram: four PostgreSQL instances (one per data store)
plus the Report Management Service that aggregates them into patient reports.
Each DB is a separate container to mirror the fact that, in a real lab, these
are owned by different systems.

```
 order-db ─┐
 case-db  ─┼─► report-service ─► report-db  ◄── (NS MCP Connector, next)
 variant-db┘   (aggregates)      (reports)
```

| Component | Role (diagram) | Container | Host port | DB / API | Credentials |
|-----------|----------------|-----------|-----------|----------|-------------|
| **Order DB**   | LIMS (OpenELIS) → *Order Info*   | `ns_order_db`   | `5433` | `order_db`   | `order_svc` / `order_pass`     |
| **Case DB**    | Tertiary Analysis → *Results*    | `ns_case_db`    | `5434` | `case_db`    | `case_svc` / `case_pass`       |
| **Variant DB** | Knowledge Base → *Variant Info*  | `ns_variant_db` | `5435` | `variant_db` | `variant_svc` / `variant_pass` |
| **Report DB**  | Report Mgmt Service → *Patient Report* | `ns_report_db` | `5436` | `report_db` | `report_svc` / `report_pass` |
| **Report Management Service** | aggregates the three source DBs → Report DB | `ns_report_service` | `8088` | HTTP API (`:8080` in-network) | — |

DB host ports are `5433`–`5436` deliberately, to stay clear of OpenELIS's own
Postgres on `5432`; the service is on `8088` because `8080` was taken. Everything
shares one Docker network (`ns-cs-poc1_default`), where services reach each other
by name (`order-db`, `case-db`, `variant-db`, `report-db` on `5432`;
`report-service` on `8080`).

## Run

The compose file now lives at the **repo root** (it orchestrates the DBs, the
backend, and the frontend), and the report-service moved to [`../backend/`](../backend/).
Run everything from the project root:

```bash
cd ..                                  # project root

docker compose up -d --build --wait    # build + start everything, wait until healthy
docker compose ps                      # status
docker compose logs report-service     # see the startup back-fill
docker compose down                    # stop (data persists in named volumes)
docker compose down -v                 # stop AND wipe data (forces re-seed next up)
```

Schema + seed under each `*/init/` run **only on first start** (empty volume).
After editing any SQL, re-seed with `docker compose down -v && docker compose up -d --wait`.

Connect with any client, e.g.:

```bash
docker exec -it ns_variant_db psql -U variant_svc -d variant_db
# or from host: psql "postgresql://variant_svc:variant_pass@localhost:5435/variant_db"
```

## Data model (summary)

**Order DB** — `patients`, `providers`, `test_catalog`, `orders`, `specimens`.
Operational store, so it holds (synthetic) PHI. De-identification is enforced
downstream at the NS MCP Connector, **not** here.

**Case DB** — `cases`, `case_variants`, `qc_metrics`, `case_files`.
Per-case tertiary-analysis output. `case_files` points at HPC/object-store paths
(the HPC layer). One case (`CASE-2026-00010`) is intentionally left `running`.

**Variant DB** — `variants`, `internal_classifications`, `external_annotations`,
`population_frequencies`, `variant_case_observations`.
The internal knowledge base. Two design points worth knowing:
- **Canonical locus key**: `variants` is unique on `(chrom,pos,ref,alt,build)` —
  build is always carried, so lookups can't silently confuse GRCh37/GRCh38.
- **Amend-not-overwrite**: a re-classification inserts a new `is_current` row and
  points the old row's `superseded_by` at it. History is never destroyed.
  `VAR000001` (BRCA1) is seeded with a VUS→Likely pathogenic upgrade to show this.

**Report DB** — `reports`, `report_variants`, `report_audit`.
Signed-out patient reports, produced by the Report Management Service. This is
the store the **NS MCP Connector** will read/write. Design points:
- **Self-contained snapshot**: patient identifiers are denormalized in at
  generation time, so it is the most PHI-dense store — hence de-id at the connector.
- **Amend-not-overwrite + audit**: re-issuing a report inserts a new `is_current`
  version, supersedes the prior one, and logs a `report_audit` row. This is the
  structure the connector's gated writes plug into.
- **Provenance**: every report carries a `provenance` JSONB of the source versions
  used (pipeline, ClinVar, gnomAD, KB classification dates).

### Cross-database keys

The three DBs are separate, so these are **logical** links (not FK-enforced across
databases) — the same keys the Report Management Service will join on:

```
order_db.orders.order_id      ── case_db.cases.order_id
order_db.specimens.accession  ── case_db.cases.accession_number
case_db.case_variants(chrom,pos,ref,alt,build) ── variant_db.variants(...)
case_db.cases.case_id         ── variant_db.variant_case_observations.case_id
```

## Seed highlights (for demos)

- `VAR000001` (BRCA1 `c.5074A>G`) is observed in **3 cases** (00001, 00002, 00007)
  across two assays — exercises variant-precedent search.
- `VAR000003` (TP53) and `VAR000006` (MYBPC3) each recur in 2 cases.
- ClinVar review status is stored at **star-level granularity** (e.g. 1-star
  conflicting vs. 4-star practice guideline), and every external/frequency record
  carries a `source_version` — both needed for defensible evidence snapshots.

All patient, provider, and coordinate data is **synthetic**. Gene names and HGVS
are realistic in form but illustrative — this is a POC KB, not data of record.

## Report Management Service API

Base URL `http://localhost:8088`. On startup it back-fills a report for every
eligible case (`analysis_status` in `complete` / `signed_out`) that lacks one —
so `CASE-2026-00010` (still `running`) has no report by design.

| Method & path | Purpose |
|---|---|
| `GET  /health` | liveness |
| `GET  /reports` | list current reports (summary) |
| `GET  /reports/{report_id}` | full report incl. variants + provenance |
| `POST /reports/generate` | back-fill missing reports (idempotent); optional body `{"case_id": "..."}` |
| `POST /reports/{case_id}/regenerate` | force a new amended version, superseding the current report |

```bash
curl -s localhost:8088/reports | python3 -m json.tool
curl -s localhost:8088/reports/RPT-2026-00001-v1 | python3 -m json.tool
curl -s -X POST localhost:8088/reports/CASE-2026-00001/regenerate
```

Aggregation is **deterministic** (no LLM): the service joins the three source DBs,
derives `overall_result` from the strongest variant classification, writes a
templated interpretation per variant, and records provenance. Interpretive
reasoning is left to the Claude Science layer.

Source lives in [`report-service/`](report-service/) — `aggregator.py` (join
logic), `writer.py` (versioned writes + audit), `main.py` (FastAPI).

## Not built here (next)

- **NS MCP Connector** → Report DB (full read/write, de-identification gate).
- Optional: point OpenELIS at the Order DB so orders flow in from the real LIMS
  instead of the synthetic seed.
