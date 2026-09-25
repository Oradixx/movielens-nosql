"""Generate a small synthetic MovieLens export in the course format (one JSON document per line).

The real file is not redistributable, so CI runs the whole pipeline on this sample instead.
The sample reuses the names and titles that the query scripts look up, and it reproduces the
data-quality issue described in the README: two different users who share the same name.

Usage (from the repository root):
    python tests/make_sample.py [output.json]
"""
import json
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
out = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'data' / 'raw' / 'sample_ratings.json'  # never overwrites the real file

rng = random.Random(42)

MOVIES = [
    (2571, 'Matrix, The (1999)'),
    (260, 'Star Wars: Episode IV - A New Hope (1977)'),
    (1196, 'Star Wars: Episode V - The Empire Strikes Back (1980)'),
    (296, 'Pulp Fiction (1994)'),
    (541, 'Blade Runner (1982)'),
    (2858, 'American Beauty (1999)'),
    (1, 'Toy Story (1995)'),
    (50, 'Usual Suspects, The (1995)'),
    (258, 'Kid in King Arthur\'s Court, A (1995)'),
    (3175, 'Galaxy Quest (1999)'),
    (1210, 'Star Wars: Episode VI - Return of the Jedi (1983)'),
    (593, 'Silence of the Lambs, The (1991)'),
]
OCCUPATIONS = ['artist', 'lawyer', 'technician/engineer', 'doctor/health care',
               'college/grad student', 'writer', 'programmer', 'retired']
FIRST = ['Barry', 'Lashandra', 'Alex', 'Mina', 'Hugo', 'Tessa', 'Omar', 'June', 'Paolo', 'Rita']
LAST = ['Erin', 'Jessie', 'Moreau', 'Kaur', 'Lindqvist', 'Okafor', 'Silva', 'Novak']

# Fixed users that the queries look up, then random ones
users = [
    {'name': 'Barry Erin', 'gender': 'M', 'age': 25, 'occupation': 'artist'},
    {'name': 'Lashandra Jessie', 'gender': 'F', 'age': 19, 'occupation': 'technician/engineer'},
    # Same name, different people: their ratings of the same movie collide in both databases
    {'name': 'Alex Twin', 'gender': 'M', 'age': 35, 'occupation': 'lawyer'},
    {'name': 'Alex Twin', 'gender': 'F', 'age': 50, 'occupation': 'writer'},
]
seen = {u['name'] for u in users}
while len(users) < 60:
    name = f'{rng.choice(FIRST)} {rng.choice(LAST)}'
    if name in seen:
        continue
    seen.add(name)
    users.append({'name': name, 'gender': rng.choice('MF'), 'age': rng.choice([18, 19, 25, 35, 45, 50, 56]),
                  'occupation': rng.choice(OCCUPATIONS)})

docs = []
for i, user in enumerate(users):
    # The two "Alex Twin" users both rate every movie, so all their pairs collide
    movies = MOVIES if user['name'] == 'Alex Twin' else rng.sample(MOVIES, rng.randint(3, len(MOVIES)))
    for movie_id, title in movies:
        docs.append({
            '_id': {'$oid': f'{len(docs):024x}'},
            'name': user['name'],
            'gender': user['gender'],
            'age': user['age'],
            'occupation': user['occupation'],
            'movie': {'id': movie_id, 'rating': rng.randint(1, 5),
                      'timestamp': 956_700_000 + rng.randint(0, 30_000_000), 'title': title},
        })

out.parent.mkdir(parents=True, exist_ok=True)
with open(out, 'w', encoding='utf-8') as f:
    for d in docs:
        f.write(json.dumps(d, ensure_ascii=False) + '\n')
print(f'{len(docs)} ratings written to {out}')
