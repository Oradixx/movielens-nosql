"""Flatten the MovieLens JSON export (one document per rating) into a CSV that both
Cassandra (cqlsh COPY) and Neo4j (LOAD CSV) can import.

Usage (from the repository root):
    python scripts/clean_data.py [input.json] [output.csv]
"""
import csv
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
input_file = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'data' / 'raw' / 'MovieLens_ratingUsers.json'
output_file = Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / 'data' / 'processed' / 'MovieLens_Cleaned.csv'

# Open the input and output files at the same time
with open(input_file, 'r', encoding='utf-8') as infile, \
     open(output_file, 'w', encoding='utf-8', newline='') as outfile:

    # ';' separator: movie titles contain commas
    writer = csv.writer(outfile, delimiter=';')

    writer.writerow(['rating_id', 'user_name', 'gender', 'age', 'occupation', 'movie_id', 'movie_title', 'rating', 'timestamp_val'])

    # Stream the file line by line (one JSON document per line) to keep memory low
    for line in infile:
        doc = json.loads(line.strip())

        # Write the flattened document directly to the CSV
        writer.writerow([
            doc['_id']['$oid'],
            doc['name'],
            doc['gender'],
            doc['age'],
            doc['occupation'],
            doc['movie']['id'],
            doc['movie']['title'],
            doc['movie']['rating'],
            doc['movie']['timestamp']
        ])

print(f"Conversion completed: {output_file}")
