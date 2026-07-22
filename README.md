# NS_CS_PoC1 — Genomic Diagnostics Lab (Claude Science PoC)

An umbrella repo containing **two separate but related sub-projects** that together
prove out extending Claude Science for a genomic diagnostics lab:

| Sub-project | What it is |
|-------------|------------|
| [`reporting-service/`](reporting-service/) | The lab data platform: four Postgres databases + the Report Management Service (FastAPI) + a React report viewer, all orchestrated by one docker-compose. |
| [`mcp-connectors/`](mcp-connectors/) | Four MCP connectors that expose those lab databases to **Claude Science** (read + a gated reclassification write + de-identification). |

```
  reporting-service/  (stands up the data + reports)          mcp-connectors/  (client)
  ┌─────────────────────────────────────────────┐            ┌────────────────────────┐
  │ order-db ─┐                                  │            │ ns-order-db            │
  │ case-db  ─┼─► report-service ─► report-db     │  reads     │ ns-case-db             │──► Claude
  │ variant-db┘   (FastAPI)          │           │ ◄────────  │ ns-variant-db (writes) │    Science
  │ frontend (React) ◄───────────────┘           │  DBs on    │ ns-report-db           │
  └─────────────────────────────────────────────┘  :5433-6   └────────────────────────┘
```

The two are decoupled: `reporting-service` runs the databases (published on
`localhost:5433–5436`); `mcp-connectors` is a client that connects to those ports.
You can run either on its own — the connectors just need the DBs up.

## Run the reporting platform

```bash
cd reporting-service
docker compose up -d --build --wait     # 6 containers, wait until healthy
```

| What | URL |
|------|-----|
| Report viewer (frontend) | http://localhost:3000 |
| Report Service API | http://localhost:8088 (`/reports`, `/stats`, `/docs`) |
| Order / Case / Variant / Report DB | `localhost:5433 / 5434 / 5435 / 5436` |

Details: [reporting-service/databases/README.md](reporting-service/databases/README.md).

## Use the connectors from Claude Science

The DBs (above) must be running. Setup + Claude Science registration is in
[mcp-connectors/README.md](mcp-connectors/README.md). The current demo dataset
includes **Mr. Dibbs** (`CASE-2026-00011`) — 2 pathogenic variants + 1 VUS — for the
end-to-end "research → reclassify VUS → re-issue report" Happy Path.

## Also here
- [`docs/`](docs/) — overarching project docs / POC plan.
- `.claude/skills/daily-update/` — project-scoped skill for drafting standup updates.

## Status
Both sub-projects are built and working end-to-end: connectors run in Claude Science
(no-sandbox mode for local DB access), and the Mr. Dibbs reclassification + amended
report have been demonstrated. Next: the `variant-curation` Skill and PDF report export.
