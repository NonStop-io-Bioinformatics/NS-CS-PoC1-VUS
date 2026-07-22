# NS MCP Connectors

Four independent MCP servers — **one per lab database** — that let Claude Science
read the lab's proprietary data and (for the knowledge base) write back a
reclassification. Each is a stdio MCP server (the local-first way Claude Science
launches custom connectors) talking to its own Postgres DB.

| Connector | DB (host port) | Mode | Tools |
|-----------|----------------|------|-------|
| **ns-order-db**   | order-db (5433)   | read-only, **de-id** | `get_patient`, `get_order`, `find_orders_for_patient`, `list_orders` |
| **ns-case-db**    | case-db (5434)    | read-only | `get_case`, `get_case_variants`, `find_cases_by_gene`, `find_cases_by_variant` + resource `case://{id}` |
| **ns-variant-db** | variant-db (5435) | read + **gated write** | `lookup_variant`, `search_variants_by_gene`, `get_classification_history`, `get_variant_precedent`, `submit_classification` |
| **ns-report-db**  | report-db (5436)  | read + **gated write**, **de-id** | `list_reports`, `get_report`, `search_reports_by_gene`, `get_report_history`, `flag_report_for_reanalysis` + resource `report://{id}` |

## Maps to the scientist workflow (the "Mr. Dibbs" flow)

1. **Find the case** — `ns-report-db`: `get_report` / `search_reports_by_gene`
2. **Import patient context** — `ns-order-db` + `ns-case-db`: order/phenotype + called variants
3. **Research the KB** — `ns-variant-db`: `lookup_variant`, `get_classification_history`, `get_variant_precedent`
4. **Reclassify** — `ns-variant-db`: `submit_classification` (VUS → LP/P or LB/B)

## Design guarantees

- **De-identification at the boundary** — order-db and report-db strip name/MRN and
  generalize DOB to birth year by default (`DEIDENTIFY=false` to disable). A stable
  `pseudonym` (patient_id token) is kept so cases can still be correlated.
- **Gated clinical writes (confirm-gate)** — `submit_classification` and
  `flag_report_for_reanalysis` do nothing on the first call (`confirm=false`); they
  return a **preview** including how many other cases are affected. Only
  `confirm=true` commits.
- **Amend-not-overwrite** — a reclassification inserts a new current version and
  supersedes the previous one; history is never destroyed.
- **Impact / precedent** — `get_variant_precedent` and the write preview surface
  every other case a variant appears in, enabling reanalysis workflows.

Reports are read-only through this connector aside from the reanalysis *flag* — a
finalized report is re-issued by regenerating it via the Report Management Service,
not by editing it here.

## Setup & run

The DBs must be up — start them from the sibling reporting-service project
(`cd ../reporting-service && docker compose up -d order-db case-db variant-db report-db`).
Create the venv the connectors run in — **use the system
Python** so the venv's base interpreter is on a system path the Claude Science
sandbox can see (a conda/home-based Python is invisible inside the sandbox):

```bash
/usr/bin/python3.12 -m venv mcp-connectors/.venv
mcp-connectors/.venv/bin/pip install -r mcp-connectors/requirements.txt
# confirm the base resolves to a system path:
readlink -f mcp-connectors/.venv/bin/python    # -> /usr/bin/python3.12
```

### Claude Science sandbox (IMPORTANT)

Claude Science runs local-command connectors inside a sandbox where **most of
`$HOME` is not visible**. Two things are required:

1. The venv's interpreter must resolve to a **system path** (done above).
2. Grant the connector directory read-only in `~/.claude-science/config.toml`:

   ```toml
   [sandbox]
   user_read_paths = ["/home/tabish/NonStop/NS_CS_PoC1/mcp-connectors"]
   ```

Then **restart Claude Science** (config is read at startup). Add each connector
via **Settings → Connectors → Add connector → Local command** (Command = the
venv python, Arguments = the `server.py` path, Environment variables = the DSN).
The DB connection to `localhost:5433–5436` triggers a **network approval card**
in the web UI — approve it. See
[`claude_science_config.example.json`](claude_science_config.example.json) for
the exact per-connector values.

## Verify

```bash
mcp-connectors/.venv/bin/python mcp-connectors/verify.py
```
Spawns each connector over stdio, lists its tools, and calls a sample read tool
(variant-db also previews `submit_classification` without writing).
