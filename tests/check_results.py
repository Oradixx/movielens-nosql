"""Check what Cassandra and Neo4j return against values computed directly from the CSV.

Run after the load scripts (see .github/workflows/e2e.yml). It uses `docker compose exec`, so
the containers from docker-compose.yml must be up.

The expected values follow each database's key rules, which is exactly where the duplicate
user names bite: Cassandra upserts on the primary key and Neo4j MERGE keeps one node or
relationship per key.
"""
import csv
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CSV = ROOT / 'data' / 'processed' / 'MovieLens_Cleaned.csv'
MATRIX = 'Matrix, The (1999)'

with open(CSV, encoding='utf-8') as f:
    rows = list(csv.DictReader(f, delimiter=';'))

failures = []


def check(label, got, expected, tol=None):
    ok = abs(got - expected) <= tol if tol is not None else got == expected
    print(f"{'OK  ' if ok else 'FAIL'} {label}: got {got}, expected {expected}")
    if not ok:
        failures.append(label)
        print(f'::error title=Check failed::{label}: got {got}, expected {expected}')  # GitHub annotation


def cql(query):
    out = subprocess.run(['docker', 'compose', 'exec', '-T', 'cassandra', 'cqlsh', '-e', query],
                         cwd=ROOT, check=True, capture_output=True, text=True).stdout
    # cqlsh prints a header, a separator line, the values, then "(n rows)"
    lines = [l.strip() for l in out.splitlines() if l.strip()]
    try:
        sep = next(i for i, l in enumerate(lines) if set(l) <= set('-+'))
        return lines[sep + 1]
    except (StopIteration, IndexError):
        print(f"::error title=Unexpected cqlsh output::{query} -> {' | '.join(lines)[:500]}")
        raise


def cypher(query):
    out = subprocess.run(['docker', 'compose', 'exec', '-T', 'neo4j', 'cypher-shell', '-u', 'neo4j',
                          '-p', 'movielens', '--format', 'plain', query],
                         cwd=ROOT, check=True, capture_output=True, text=True).stdout
    lines = out.splitlines()
    if len(lines) < 2:
        print(f"::error title=Unexpected cypher-shell output::{query} -> {out[:500]}")
    return lines[1].strip()


# --- Expected values, from the CSV ------------------------------------------------------------
# Cassandra user_activity: PRIMARY KEY ((user_name), movie_id)
barry_movies = {r['movie_id'] for r in rows if r['user_name'] == 'Barry Erin'}
# Cassandra movie_trends: PRIMARY KEY ((movie_title), rating, timestamp_val, user_name)
matrix_keys = {(r['rating'], r['timestamp_val'], r['user_name']) for r in rows if r['movie_title'] == MATRIX}
matrix_avg = sum(int(k[0]) for k in matrix_keys) / len(matrix_keys)
# Neo4j: MERGE on user name, movie id, occupation name, and one RATED per (user, movie)
users = {r['user_name'] for r in rows}
movies = {r['movie_id'] for r in rows}
occupations = {r['occupation'] for r in rows}
rated = {(r['user_name'], r['movie_id']) for r in rows}
works_as = {(r['user_name'], r['occupation']) for r in rows}

print(f'{len(rows)} CSV rows, {len(users)} distinct user names, {len(rows) - len(rated)} colliding ratings\n')

# --- Cassandra --------------------------------------------------------------------------------
check('Cassandra rows per table (movie_trends)', int(cql('SELECT COUNT(*) FROM movielens.movie_trends;')),
      len({(r['movie_title'], r['rating'], r['timestamp_val'], r['user_name']) for r in rows}))
check("Cassandra movies rated by 'Barry Erin'",
      int(cql("SELECT COUNT(*) FROM movielens.user_activity WHERE user_name = 'Barry Erin';")), len(barry_movies))
check('Cassandra true_average (UDA) for The Matrix',
      float(cql(f"SELECT movielens.true_average(rating) FROM movielens.movie_trends "
                f"WHERE movie_title = '{MATRIX}';")),
      matrix_avg, tol=1e-6)  # cqlsh rounds doubles

# --- Neo4j ------------------------------------------------------------------------------------
check('Neo4j nodes', int(cypher('MATCH (n) RETURN count(n);')), len(users) + len(movies) + len(occupations))
check('Neo4j RATED relationships', int(cypher('MATCH ()-[r:RATED]->() RETURN count(r);')), len(rated))
check('Neo4j WORKS_AS relationships', int(cypher('MATCH ()-[r:WORKS_AS]->() RETURN count(r);')), len(works_as))
check('Duplicate name collapses into one User node',
      int(cypher("MATCH (u:User {user_name: 'Alex Twin'}) RETURN count(u);")), 1)

if failures:
    sys.exit(f'\n{len(failures)} check(s) failed')
print('\nAll checks passed')
