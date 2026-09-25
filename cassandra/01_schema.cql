-- Cassandra data model: one table per query pattern (query-first design).
-- The same 1,000,209 ratings are denormalised into three tables, each partitioned
-- for a different access path.

-- Start from a clean keyspace (a first version had tables that were too generic)
DROP KEYSPACE IF EXISTS movielens;

-- Single node for this project, so replication factor 1
CREATE KEYSPACE movielens
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

USE movielens;

-- TABLE A: the full history of one user
-- Partition = user, rows sorted by movie
CREATE TABLE user_activity (
    user_name text,
    movie_id int,
    rating_id text,
    gender text,
    age int,
    occupation text,
    movie_title text,
    rating int,
    timestamp_val int,
    PRIMARY KEY ((user_name), movie_id)
);

-- TABLE B: demographic analysis by job
-- Partition = occupation; clustering columns allow filtering by gender, then age
CREATE TABLE demographic_analysis (
    occupation text,
    gender text,
    age int,
    user_name text,
    movie_id int,
    rating_id text,
    movie_title text,
    rating int,
    timestamp_val int,
    PRIMARY KEY ((occupation), gender, age, user_name, movie_id)
);

-- TABLE C: trends for one movie
-- Partition = movie; best and most recent ratings first
CREATE TABLE movie_trends (
    movie_title text,
    rating int,
    timestamp_val int,
    user_name text,
    movie_id int,
    rating_id text,
    gender text,
    age int,
    occupation text,
    PRIMARY KEY ((movie_title), rating, timestamp_val, user_name)
) WITH CLUSTERING ORDER BY (rating DESC, timestamp_val DESC);
