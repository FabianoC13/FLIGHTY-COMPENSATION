#!/usr/bin/env python3
"""Regenerate FlightCompensation/Resources/airports.json from OurAirports (public domain).

    curl -sSL -o /tmp/airports.csv https://davidmegginson.github.io/ourairports-data/airports.csv
    python3 scripts/generate_airports.py /tmp/airports.csv

Output: {"IATA": ["ISO country", lat, lon], ...}, one entry per IATA code, preferring
large/medium airports with scheduled service when a code is shared.
"""
import csv
import json
import sys
from pathlib import Path

PRIORITY = {"large_airport": 0, "medium_airport": 1, "small_airport": 2, "seaplane_base": 3, "heliport": 4}
OUT = Path(__file__).resolve().parent.parent / "FlightCompensation" / "Resources" / "airports.json"


def main(csv_path: str) -> None:
    best = {}
    with open(csv_path, encoding="utf-8") as f:
        for row in csv.DictReader(f):
            code = (row["iata_code"] or "").strip().upper()
            if len(code) != 3 or not code.isalpha() or row["type"] == "closed":
                continue
            rank = (PRIORITY.get(row["type"], 5), 0 if row["scheduled_service"] == "yes" else 1)
            if code in best and best[code][0] <= rank:
                continue
            best[code] = (rank, [row["iso_country"], round(float(row["latitude_deg"]), 4), round(float(row["longitude_deg"]), 4)])
    data = {code: value for code, (_, value) in sorted(best.items())}
    OUT.write_text(json.dumps(data, separators=(",", ":")))
    print(f"Wrote {len(data)} airports to {OUT}")


if __name__ == "__main__":
    main(sys.argv[1])
