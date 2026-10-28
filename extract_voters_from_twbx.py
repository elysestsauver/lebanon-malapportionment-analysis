"""
extract_voters_from_twbx.py

Recovers the 2022 Lebanese voter-roll table from the Tableau workbook
"Registered Voters by District.twbx" and saves it as a plain CSV, which
clean_registered_voters_2022.R then turns into the analysis datasets.

A .twbx file is a zip archive. Its data are stored in a Tableau "Hyper" extract
(Data/Extracts/*.hyper), which holds the voter table
"20220428 district populations.csv" with all 3,967,507 registered voters.
This script reads that table directly with Tableau's free Hyper API. Do not
export the table from Tableau instead: Tableau's CSV export dropped 313,375 of
the rows.

Requirements: Python 3 and Tableau's Hyper API, version 0.0.26479 (the newest
release with builds for macOS, Windows, and Linux):
    pip install tableauhyperapi==0.0.26479

Usage, from the folder containing the workbook:
    python3 extract_voters_from_twbx.py "Registered Voters by District.twbx"

Output: "District RVs Extracted from Tableau.csv", UTF-8 and comma-separated,
with one row per registered voter and the original column names.
"""

import csv
import sys
import tempfile
import zipfile

from tableauhyperapi import Connection, CreateMode, HyperProcess, Telemetry, escape_name

VOTER_TABLE = "20220428 district populations.csv"   # table name inside the extract
OUTPUT_CSV = "District RVs Extracted from Tableau.csv"
EXPECTED_ROWS = 3_967_507                            # registered voters in 2022

# Rows are sorted so the CSV comes out identical every time: by place first,
# then by every remaining column.
SORT_FIRST = ["governate", "elect_district", "cadaa", "town_neighbmatch", "regnumber", "sex"]


def extract_voters(twbx_path, csv_path=OUTPUT_CSV):
    with tempfile.TemporaryDirectory() as tmp:

        # 1. Unzip the Hyper extract from the packaged workbook.
        with zipfile.ZipFile(twbx_path) as twbx:
            [hyper_name] = [n for n in twbx.namelist() if n.endswith(".hyper")]
            hyper_path = twbx.extract(hyper_name, tmp)

        # 2. Copy the voter table to CSV, row by row. Missing values become "".
        with HyperProcess(Telemetry.DO_NOT_SEND_USAGE_DATA_TO_TABLEAU,
                          parameters={"log_dir": tmp}) as hyper, \
             Connection(hyper.endpoint, hyper_path, CreateMode.NONE) as con:

            # Tableau appends an ID to the table name, so match on its start.
            [table] = [t for t in con.catalog.get_table_names("Extract")
                       if t.name.unescaped.startswith(VOTER_TABLE)]
            columns = [c.name.unescaped
                       for c in con.catalog.get_table_definition(table).columns]

            sort_order = SORT_FIRST + [c for c in columns if c not in SORT_FIRST]
            query = (f"SELECT * FROM {table} ORDER BY "
                     + ", ".join(escape_name(c) for c in sort_order))

            n_rows = 0
            with open(csv_path, "w", encoding="utf-8", newline="") as out, \
                 con.execute_query(query) as rows:
                writer = csv.writer(out, lineterminator="\n")
                writer.writerow(columns)
                for row in rows:
                    writer.writerow(["" if value is None else value for value in row])
                    n_rows += 1

    print(f"Wrote {n_rows:,} voters to {csv_path}")
    if n_rows != EXPECTED_ROWS:
        sys.exit(f"Error: expected {EXPECTED_ROWS:,} voters but found {n_rows:,}.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit('Usage: python3 extract_voters_from_twbx.py "Registered Voters by District.twbx"')
    extract_voters(sys.argv[1])
