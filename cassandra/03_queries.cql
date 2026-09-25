-- Queries: each one reads a single partition of the table designed for it.
USE movielens;

-- Q1. Full history of one user (user_activity, partition = user_name)
SELECT movie_title, rating
FROM user_activity
WHERE user_name = 'Barry Erin';

-- Q2. Specific movies of one user: partition key + IN on the clustering column
SELECT movie_title, rating, timestamp_val
FROM user_activity
WHERE user_name = 'Barry Erin' AND movie_id IN (1, 50, 258);

-- Q3. Male artists (demographic_analysis, partition = occupation, filter on the 1st clustering column)
SELECT user_name, age, movie_title, rating
FROM demographic_analysis
WHERE occupation = 'artist' AND gender = 'M'
LIMIT 15;

-- Q4. 19-year-old female engineers: filter on the first two clustering columns, in order
SELECT user_name, movie_title, rating
FROM demographic_analysis
WHERE occupation = 'technician/engineer' AND gender = 'F' AND age = 19
LIMIT 15;

-- Q5. Latest top ratings of a movie (movie_trends is sorted by rating DESC, then timestamp DESC)
SELECT user_name, rating, timestamp_val
FROM movie_trends
WHERE movie_title = 'Pulp Fiction (1994)'
LIMIT 15;

-- Q6. Who gave 1 star to Star Wars, most recent first
SELECT user_name, age, occupation, timestamp_val
FROM movie_trends
WHERE movie_title = 'Star Wars: Episode IV - A New Hope (1977)' AND rating = 1
LIMIT 15;

-- Q7. Number of movies rated by one user (original result: 341)
SELECT COUNT(*) AS total_rated_movies
FROM user_activity
WHERE user_name = 'Barry Erin';

-- Q8. Average rating of lawyers
-- AVG on an int column returns an int: the original result was 3, not the real mean.
SELECT AVG(rating) AS lawyers_avg_rating
FROM demographic_analysis
WHERE occupation = 'lawyer';

-- Q9. User-defined aggregate for a real (decimal) average
-- Needs user_defined_functions_enabled: true in cassandra.yaml (set in docker-compose.yml).

-- state function: count the values and add them up
CREATE OR REPLACE FUNCTION custom_avg_state (state tuple<int, bigint>, val int)
CALLED ON NULL INPUT RETURNS tuple<int, bigint> LANGUAGE java
AS 'if (val != null) { state.setInt(0, state.getInt(0) + 1); state.setLong(1, state.getLong(1) + val.intValue()); } return state;';

-- final function: divide the sum by the count
CREATE OR REPLACE FUNCTION custom_avg_final (state tuple<int, bigint>)
CALLED ON NULL INPUT RETURNS double LANGUAGE java
AS 'double r = 0; if (state.getInt(0) == 0) return null; r = state.getLong(1); r /= state.getInt(0); return Double.valueOf(r);';

-- aggregate built from the two functions
CREATE AGGREGATE IF NOT EXISTS true_average (int)
SFUNC custom_avg_state STYPE tuple<int, bigint>
FINALFUNC custom_avg_final INITCOND (0, 0);

-- Original result: 4.315830115830116
SELECT true_average(rating) AS mean_rating
FROM movie_trends
WHERE movie_title = 'Matrix, The (1999)';
