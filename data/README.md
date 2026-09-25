# Data

Not included in this repository.

The course provided `MovieLens_ratingUsers.json` (about 240 MB): the **MovieLens 1M** ratings
([GroupLens](https://grouplens.org/datasets/movielens/1m/)), exported as one JSON document per rating,
with generated user names instead of user ids:

```json
{ "_id": { "$oid": "..." }, "name": "...", "gender": "M", "age": 32, "occupation": "doctor/health care",
  "movie": { "id": 573, "rating": 4, "timestamp": 956704056, "title": "..." } }
```

1. Put the file in `data/raw/`.
2. Run `python scripts/clean_data.py`: it writes `data/processed/MovieLens_Cleaned.csv` (about 100 MB, 1,000,209 rows,
   `;`-separated), which `docker-compose.yml` mounts into both containers.

| Column | Content |
|---|---|
| `rating_id` | MongoDB-style id of the rating document |
| `user_name`, `gender`, `age`, `occupation` | user profile (`user_name` is not unique: see the main README) |
| `movie_id`, `movie_title` | movie |
| `rating` | 1 to 5 |
| `timestamp_val` | Unix timestamp of the rating |
