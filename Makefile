# Run every target from solution/part_2/ (all paths are relative to it).
# dbt is always called through `uv run` so the project env (dbt-core + dbt-duckdb)
# is used, never a global dbt install (e.g. dbt-fusion).

unexport VIRTUAL_ENV
DBT := uv run dbt --no-version-check
DBT_ARGS := --project-dir ocbc_dbt --profiles-dir ocbc_dbt
FACTS := fct_revenue_by_category fct_revenue_by_product fct_high_income_usage_by_category fct_high_income_usage_by_product

.PHONY: help install data dbt answers ui clean

help:
	@echo "make install  - create .venv with duckdb, dbt-core, dbt-duckdb"
	@echo "make data     - split dataset/raw/AE Test_1126.xlsx into dataset/{transaction,profile,porto}.csv"
	@echo "make dbt      - dbt build (models + tests) into dbt.duckdb"
	@echo "make answers  - make dbt, then print the 4 fact tables (the Q1 / Q2 answers)"
	@echo "make ui       - DuckDB UI on dbt.duckdb (http://localhost:4213); stop it before make dbt"
	@echo "make clean    - delete dbt.duckdb and dbt artifacts"

install:
	uv sync

data:
	uv run scripts/extract_dataset.py

dbt:
	$(DBT) build $(DBT_ARGS)

answers: dbt
	@uv run python -c "import duckdb; c = duckdb.connect('dbt.duckdb', read_only=True); [(print(t), c.sql(f'from {t}').show(max_rows=100, max_width=200)) for t in '$(FACTS)'.split()]"

ui:
	uv run python scripts/ui.py

clean:
	rm -f dbt.duckdb dbt.duckdb.wal
	rm -rf ocbc_dbt/target ocbc_dbt/logs
