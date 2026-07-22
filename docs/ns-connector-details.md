# NS MCP Connector Details

Configuration values for the four NS MCP connectors, as entered in Claude Science:
**Settings → Connectors → Add connector → Local command** (Arguments and
Environment variables are under *Advanced settings*).

**Prerequisite:** the databases must be running —
`cd reporting-service && docker compose up -d order-db case-db variant-db report-db`

**Shared Command** (identical for all four — the connectors' venv Python):

```
/home/tabish/NonStop/NS_CS_PoC1/mcp-connectors/.venv/bin/python
```

Only the **Arguments** (which server) and **Environment variables** (which DB) differ.
Environment variables are `KEY` / `VALUE` pairs (one per row).

---

## 1. ns-order-db  — LIMS orders/patients (read-only, de-identified)

| Field | Value |
|-------|-------|
| **Name** | `ns-order-db` |
| **Command** | `/home/tabish/NonStop/NS_CS_PoC1/mcp-connectors/.venv/bin/python` |
| **Arguments** | `/home/tabish/NonStop/NS_CS_PoC1/mcp-connectors/order-db/server.py` |

| Env key | Env value |
|---------|-----------|
| `ORDER_DB_DSN` | `postgresql://order_svc:order_pass@localhost:5433/order_db` |
| `DEIDENTIFY` | `true` |

---

## 2. ns-case-db  — tertiary-analysis results / called variants (read-only)

| Field | Value |
|-------|-------|
| **Name** | `ns-case-db` |
| **Command** | `/home/tabish/NonStop/NS_CS_PoC1/mcp-connectors/.venv/bin/python` |
| **Arguments** | `/home/tabish/NonStop/NS_CS_PoC1/mcp-connectors/case-db/server.py` |

| Env key | Env value |
|---------|-----------|
| `CASE_DB_DSN` | `postgresql://case_svc:case_pass@localhost:5434/case_db` |

---

## 3. ns-variant-db  — internal knowledge base (read + gated reclassification write)

| Field | Value |
|-------|-------|
| **Name** | `ns-variant-db` |
| **Command** | `/home/tabish/NonStop/NS_CS_PoC1/mcp-connectors/.venv/bin/python` |
| **Arguments** | `/home/tabish/NonStop/NS_CS_PoC1/mcp-connectors/variant-db/server.py` |

| Env key | Env value |
|---------|-----------|
| `VARIANT_DB_DSN` | `postgresql://variant_svc:variant_pass@localhost:5435/variant_db` |

> Keep the `submit_classification` tool on **Ask each time** — it's the gated clinical write.

---

## 4. ns-report-db  — signed-out patient reports (read + gated reanalysis flag, de-identified)

| Field | Value |
|-------|-------|
| **Name** | `ns-report-db` |
| **Command** | `/home/tabish/NonStop/NS_CS_PoC1/mcp-connectors/.venv/bin/python` |
| **Arguments** | `/home/tabish/NonStop/NS_CS_PoC1/mcp-connectors/report-db/server.py` |

| Env key | Env value |
|---------|-----------|
| `REPORT_DB_DSN` | `postgresql://report_svc:report_pass@localhost:5436/report_db` |
| `DEIDENTIFY` | `true` |

---

## Notes
- DSNs use `localhost` because Claude Science runs with `--dangerously-no-sandbox`,
  so the connectors run on the host and reach the DB ports directly.
- Ports `5433–5436` map to order / case / variant / report DB respectively.
- These match the live registrations in `~/.claude-science/mcp/local-mcp.json`.
