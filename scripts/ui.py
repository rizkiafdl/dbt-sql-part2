"""Start the DuckDB UI on the dbt output (the DuckDB CLI is not required).

Run from solution/part_2/: `make ui`. Opens an in-memory DuckDB and attaches
dbt.duckdb read-only as `dbt`, so every stg_ / dim_ / fct_ table is browsable.
Raw files can be queried directly, e.g. select * from 'dataset/porto.csv'.
While the UI runs, `make dbt` fails with a lock error: stop the UI first.
The UI frontend loads from ui.duckdb.org; queries and data stay local.
"""
import signal
import sys
import time
from pathlib import Path

import duckdb

DB = Path(__file__).resolve().parent.parent / "dbt.duckdb"
if not DB.exists():
    sys.exit(f"{DB.name} not found: run `make dbt` first.")

# Make Ctrl+C (SIGINT) and SIGTERM always stop the loop below, even if the
# parent process started us with SIGINT ignored.
signal.signal(signal.SIGINT, signal.default_int_handler)
signal.signal(signal.SIGTERM, signal.default_int_handler)

con = duckdb.connect()
con.execute(f"ATTACH '{DB}' AS dbt (READ_ONLY)")
con.execute("CALL start_ui()")
print("DuckDB UI: http://localhost:4213  (Ctrl+C to stop)", flush=True)
print("dbt tables: dbt.main.*   raw files: select * from 'dataset/porto.csv'")
print("Stop the UI before `make dbt` (lock on dbt.duckdb).", flush=True)
try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    pass
finally:
    con.close()
