"""Thin psycopg3 helpers: dict-row connections and startup wait loops."""
import time
import psycopg
from psycopg.rows import dict_row


def connect(dsn):
    """Open a dict-row connection (manual transaction control)."""
    return psycopg.connect(dsn, row_factory=dict_row)


def wait_for(dsn, name, timeout=120):
    """Block until the database accepts connections, or raise."""
    deadline = time.time() + timeout
    last = None
    while time.time() < deadline:
        try:
            with psycopg.connect(dsn, connect_timeout=3):
                return
        except Exception as e:  # noqa: BLE001 - startup resilience
            last = e
            time.sleep(2)
    raise RuntimeError(f"database '{name}' not reachable after {timeout}s: {last}")


def wait_for_table(dsn, table, timeout=120):
    """Block until a table exists (covers the postgres init-script race)."""
    deadline = time.time() + timeout
    last = None
    while time.time() < deadline:
        try:
            with psycopg.connect(dsn) as c, c.cursor() as cur:
                cur.execute("SELECT to_regclass(%s)", (table,))
                if cur.fetchone()[0] is not None:
                    return
        except Exception as e:  # noqa: BLE001
            last = e
        time.sleep(2)
    raise RuntimeError(f"table '{table}' not present after {timeout}s: {last}")
