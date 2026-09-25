-- Load the same CSV into the three tables with cqlsh COPY.
-- Original run: 1,000,209 rows per table in about 10 s each (~99,000 rows/s).
USE movielens;

COPY user_activity (rating_id, user_name, gender, age, occupation, movie_id, movie_title, rating, timestamp_val)
FROM '/data/MovieLens_Cleaned.csv' WITH HEADER = TRUE AND DELIMITER = ';';

COPY demographic_analysis (rating_id, user_name, gender, age, occupation, movie_id, movie_title, rating, timestamp_val)
FROM '/data/MovieLens_Cleaned.csv' WITH HEADER = TRUE AND DELIMITER = ';';

COPY movie_trends (rating_id, user_name, gender, age, occupation, movie_id, movie_title, rating, timestamp_val)
FROM '/data/MovieLens_Cleaned.csv' WITH HEADER = TRUE AND DELIMITER = ';';
