# /// script
# requires-python = ">=3.10"
# dependencies = ["openpyxl>=3.1"]
# ///
"""Extract the data sheets of the assessment workbook into CSV files.

Source: dataset/raw/AE Test_1126.xlsx (a copy of the workbook, shipped with the project).
Output: dataset/transaction.csv, dataset/profile.csv, dataset/porto.csv (the dbt sources).

Usage (from solution/part_2/):
    make data
    uv run scripts/extract_dataset.py --xlsx other.xlsx --out some_dir

openpyxl comes from the inline script metadata above, so `uv run` installs it
in a throwaway env; it is not a project dependency.

Export rules (no data cleaning is done):
- One CSV per sheet: transaction, profile, porto. Header row is kept as is.
- Datetime cells are written as YYYY-MM-DD (the source has no time parts;
  the script fails if it finds one, so no information is lost silently).
- Rows where every cell is empty are skipped (the sheets contain many
  empty formatted rows).
- Empty cells inside a data row are written as empty fields.
- All other values are written as stored in the workbook.
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
from pathlib import Path

import openpyxl

SHEETS = ("transaction", "profile", "porto")
PART2_DIR = Path(__file__).resolve().parent.parent
DEFAULT_XLSX = PART2_DIR / "dataset" / "raw" / "AE Test_1126.xlsx"
DEFAULT_OUT = PART2_DIR / "dataset"


def to_csv_value(value: object, sheet: str, row_no: int) -> object:
    if isinstance(value, dt.datetime):
        if value.time() != dt.time(0):
            raise ValueError(
                f"{sheet} row {row_no}: datetime {value} has a time part; "
                "update the export rule before continuing"
            )
        return value.strftime("%Y-%m-%d")
    if isinstance(value, dt.date):
        return value.strftime("%Y-%m-%d")
    return value


def export_sheet(wb: openpyxl.Workbook, sheet: str, out_dir: Path) -> int:
    out_path = out_dir / f"{sheet}.csv"
    data_rows = 0
    with out_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        for row_no, row in enumerate(wb[sheet].iter_rows(values_only=True), start=1):
            if all(v is None for v in row):
                continue
            writer.writerow([to_csv_value(v, sheet, row_no) for v in row])
            data_rows += 1
    return data_rows - 1  # exclude header


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Extract the data sheets of the assessment workbook into CSV files."
    )
    parser.add_argument("--xlsx", type=Path, default=DEFAULT_XLSX, help="source workbook")
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT, help="output directory")
    args = parser.parse_args()

    if not args.xlsx.is_file():
        raise SystemExit(f"Workbook not found: {args.xlsx}")
    args.out.mkdir(parents=True, exist_ok=True)

    wb = openpyxl.load_workbook(args.xlsx, read_only=True, data_only=True)
    try:
        missing = [s for s in SHEETS if s not in wb.sheetnames]
        if missing:
            raise SystemExit(f"Sheets not found in workbook: {missing}")
        for sheet in SHEETS:
            rows = export_sheet(wb, sheet, args.out)
            print(f"{sheet:<12} {rows:>6} rows -> {args.out / (sheet + '.csv')}")
    finally:
        wb.close()


if __name__ == "__main__":
    main()
