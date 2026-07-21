# NS_CS_PoC1 — Genomic Diagnostics Lab (Claude Science PoC)

A working model of a genomic diagnostics lab's data plane, plus a report viewer.
It stands in for the lab-side systems that the **NS MCP Connector** (the core PoC
deliverable, not yet built) will expose to Claude Science.

## Architecture

```
 order-db ─┐
 case-db  ─┼─►  report-service  ─►  report-db  ─►  frontend (React)
 variant-db┘    (FastAPI, backend/)   (reports)     via /api proxy
                                          ▲
                                          └── NS MCP Connector (next)
```

- **order-db / case-db / variant-db** — lab source databases (LIMS/OpenELIS,
  Tertiary Analysis, Knowledge Base). Postgres, schema + synthetic seed data.
- **report-db** — signed-out patient reports (versioned, provenance, audit).
- **report-service** (`backend/`) — FastAPI. Aggregates the three source DBs into
  reports (auto back-fill on startup) **and** serves the read API for the viewer.
- **frontend/** — React (Vite) report viewer, served by nginx which proxies
  `/api` to the backend.

## Quick start

```bash
docker compose up -d --build --wait     # build + start everything, wait until healthy
docker compose ps                        # all 6 should be healthy
docker compose logs report-service       # see the report back-fill on startup
```

Then open:

| What | URL |
|------|-----|
| **Report viewer (frontend)** | http://localhost:3000 |
| Backend API (direct)         | http://localhost:8088  (e.g. `/reports`, `/stats`, `/docs`) |
| Order / Case / Variant / Report DB | `localhost:5433 / 5434 / 5435 / 5436` |

DB host ports are `5433`–`5436` to stay clear of OpenELIS's `5432`; the backend is
on `8088` (8080 was taken) and the frontend on `3000`.

## Teardown / reset

```bash
docker compose down          # stop; data persists in named volumes
docker compose down -v       # stop AND wipe data (forces DB re-seed + report re-gen)
```

## Layout

```
databases/    DB schemas + synthetic seed SQL (see databases/README.md)
backend/      FastAPI report-service (aggregation + read API)
frontend/     React report viewer
docker-compose.yml   orchestrates all tiers
```

## Not built yet (next)

- **NS MCP Connector** → Report DB: read tools, gated write path, de-identification
  gate. This is the actual PoC deliverable.
- Optional: wire OpenELIS to feed the Order DB instead of the synthetic seed.
