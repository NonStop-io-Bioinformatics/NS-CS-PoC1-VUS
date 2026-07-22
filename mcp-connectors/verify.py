"""Smoke-test all four NS MCP connectors over stdio.

Spawns each server as Claude Science would (stdio), lists its tools, and calls a
sample read tool. For variant-db it also exercises submit_classification in
PREVIEW mode (confirm=false) so nothing is written.

Requires the DBs running (docker compose up -d order-db case-db variant-db report-db)
and `mcp` + `psycopg[binary]` installed in the current interpreter.

    python verify.py
"""
import asyncio
import os
import sys

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

HERE = os.path.dirname(os.path.abspath(__file__))
PY = sys.executable

CONNECTORS = {
    "order-db": {
        "script": os.path.join(HERE, "order-db", "server.py"),
        "env": {"ORDER_DB_DSN": "postgresql://order_svc:order_pass@localhost:5433/order_db", "DEIDENTIFY": "true"},
        "calls": [("get_order", {"order_id": "ORD-2026-00001"})],
    },
    "case-db": {
        "script": os.path.join(HERE, "case-db", "server.py"),
        "env": {"CASE_DB_DSN": "postgresql://case_svc:case_pass@localhost:5434/case_db"},
        "calls": [("get_case_variants", {"case_id": "CASE-2026-00001"})],
    },
    "variant-db": {
        "script": os.path.join(HERE, "variant-db", "server.py"),
        "env": {"VARIANT_DB_DSN": "postgresql://variant_svc:variant_pass@localhost:5435/variant_db"},
        "calls": [
            ("lookup_variant", {"chrom": "17", "pos": 43093867, "ref": "A", "alt": "G"}),
            ("submit_classification", {
                "variant_id": "VAR000004", "classification": "Likely pathogenic",
                "acmg_criteria": ["PM2", "PP3"], "evidence_summary": "verify.py preview only",
                "classified_by": "verify.py", "confirm": False,
            }),
        ],
    },
    "report-db": {
        "script": os.path.join(HERE, "report-db", "server.py"),
        "env": {"REPORT_DB_DSN": "postgresql://report_svc:report_pass@localhost:5436/report_db", "DEIDENTIFY": "true"},
        "calls": [("list_reports", {"limit": 3})],
    },
}


async def check(name, cfg):
    params = StdioServerParameters(command=PY, args=[cfg["script"]], env={**os.environ, **cfg["env"]})
    async with stdio_client(params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            tools = await session.list_tools()
            print(f"\n=== {name}: {len(tools.tools)} tools -> {[t.name for t in tools.tools]}")
            for tool, args in cfg["calls"]:
                res = await session.call_tool(tool, args)
                text = res.content[0].text if res.content else "(no content)"
                print(f"  {tool}: {text[:280]}")


async def main():
    ok = True
    for name, cfg in CONNECTORS.items():
        try:
            await check(name, cfg)
        except Exception as e:  # noqa: BLE001
            ok = False
            print(f"\n!! {name} FAILED: {type(e).__name__}: {e}")
    print("\n" + ("ALL CONNECTORS OK" if ok else "SOME CONNECTORS FAILED"))


if __name__ == "__main__":
    asyncio.run(main())
