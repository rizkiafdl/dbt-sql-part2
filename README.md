# OCBC AE Test — Part 2 (SQL + dbt)

A dbt project on DuckDB that answers the two Part 2 questions:

1. Which product or product category is the biggest contributor to revenue?
2. Which product or product category do high-income customers usually use?

The written answers and assumptions are in [answer.md](answer.md). This README covers only setup and running.

## What's inside

```
dataset/            profile.csv, porto.csv, transaction.csv (the raw data)
dataset/raw/        AE Test_1126.xlsx (the original workbook)
ocbc_dbt/           the dbt project (models, sources, profiles.yml)
scripts/ui.py       starts the DuckDB UI on the dbt output
scripts/extract_dataset.py   splits the workbook into the CSV files
Makefile            shortcuts for every step below
```

Model lineage (`raw → staging → mart`):

```
raw.profile ─► stg_profile ─► dim_customer ─┐
                                            ├─► fct_high_income_usage_by_category   (Q2)
raw.porto   ─► stg_porto ──┬────────────────┘   fct_high_income_usage_by_product    (Q2)
                           ├─► fct_revenue_by_category                              (Q1)
                           └─► fct_revenue_by_product                               (Q1)
```

The database is a single local file, `dbt.duckdb`. No server or account is needed.

## 1. Install the tools

You need **git** and **uv**. uv installs the right Python (3.12+) and all packages for you, so you do not need to install Python yourself.

| OS | Install uv | Install make |
|---|---|---|
| macOS | `brew install uv` or `curl -LsSf https://astral.sh/uv/install.sh \| sh` | Already there (if not: `xcode-select --install`) |
| Linux | `curl -LsSf https://astral.sh/uv/install.sh \| sh` | `sudo apt install make` (Debian/Ubuntu) |
| Windows | `powershell -c "irm https://astral.sh/uv/install.ps1 \| iex"` | Optional. Use the commands in [Windows without make](#windows-without-make). |

Open a new terminal after installing, then check with `uv --version`.

## 2. Get the project

```bash
git clone https://github.com/rizkiafdl/dbt-sql-part2.git
cd dbt-sql-part2
```

If you got the project as a zip, unzip it and `cd` into the folder.

**Run every command below from this folder.** The dbt profile and the CSV paths are relative to it.

## 3. Set up and run

```bash
make install    # create .venv with dbt-core, dbt-duckdb and duckdb
make answers    # build all models, run the tests, print the 4 answer tables
```

`make answers` should end with all tests passing (`PASS=14`), followed by the 4 fact tables.

All the steps:

| Command | What it does |
|---|---|
| `make install` | Create `.venv` and install the packages from `uv.lock`. |
| `make data` | Optional. Re-create `dataset/*.csv` from `dataset/raw/AE Test_1126.xlsx`. The CSV files are already included. |
| `make dbt` | Build all models into `dbt.duckdb` and run the tests (`dbt build`). |
| `make answers` | Run `make dbt`, then print the 4 fact tables. |
| `make ui` | Open the DuckDB UI in your browser to query the models. |
| `make clean` | Delete `dbt.duckdb` and the dbt `target/` and `logs/` folders. |

> Always run dbt through `uv run` or `make`. If you have another `dbt` on your machine (for example dbt Cloud CLI or dbt Fusion), plain `dbt` may call that one instead of this project's dbt-core.

## 4. Query the models

### In the browser (DuckDB UI)

```bash
make ui
```

Open http://localhost:4213. The models are attached as `dbt.main`, so write queries like:

```sql
from dbt.main.fct_revenue_by_category;

from dbt.main.fct_high_income_usage_by_product
where product = 'BANCA';

-- the raw CSV files work too
from 'dataset/porto.csv' limit 10;
```

Press **Ctrl+C** in the terminal to stop the UI.

- The UI page loads from `ui.duckdb.org`, so the browser needs internet. Your data and queries stay on your machine.
- **Stop the UI before you run `make dbt` again.** DuckDB lets only one process write to `dbt.duckdb`, and the UI keeps it open.

### In the terminal

```bash
uv run python -c "import duckdb; duckdb.connect('dbt.duckdb', read_only=True).sql('from fct_revenue_by_product order by total_balance desc limit 5').show()"
```

If you have the DuckDB CLI installed, `duckdb -readonly dbt.duckdb` also works.

## Windows without make

Run these in PowerShell from the project folder:

```powershell
uv sync                                                                     # make install
uv run scripts/extract_dataset.py                                           # make data (optional)
uv run dbt --no-version-check build --project-dir ocbc_dbt --profiles-dir ocbc_dbt   # make dbt
uv run python scripts/ui.py                                                 # make ui
```

To print one answer table:

```powershell
uv run python -c "import duckdb; duckdb.connect('dbt.duckdb', read_only=True).sql('from fct_revenue_by_category').show()"
```

The 4 answer tables are `fct_revenue_by_category`, `fct_revenue_by_product`, `fct_high_income_usage_by_category` and `fct_high_income_usage_by_product`.

## Troubleshooting

| Problem | Fix |
|---|---|
| `Could not set lock on file "dbt.duckdb"` | The DuckDB UI (or another session) has the file open. Stop it with Ctrl+C, then run `make dbt` again. |
| `dbt.duckdb not found: run make dbt first.` | `make ui` needs the database. Run `make dbt` first. |
| `uv: command not found` | Open a new terminal after installing uv, or add it to your `PATH`. |
| dbt errors about the profile, or about missing `dataset/...csv` | You are not in the project folder. `cd` into it and run the command again. |
| Wrong dbt version or unknown flags | You called a global `dbt`. Use `make` or `uv run dbt ...`. |
