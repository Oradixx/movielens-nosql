// Graph model:
//   (:User {user_name, age, gender})-[:WORKS_AS]->(:Occupation {name})
//   (:User)-[:RATED {rating, timestamp_val}]->(:Movie {movie_id, title})
// The occupation is a node rather than a property, so users can be grouped by job
// through the graph and the job names are not repeated on every user.

// Uniqueness constraints: data integrity + indexes that speed up MERGE during the import
CREATE CONSTRAINT occupation_name_unique IF NOT EXISTS FOR (o:Occupation) REQUIRE o.name IS UNIQUE;
CREATE CONSTRAINT movie_id_unique IF NOT EXISTS FOR (m:Movie) REQUIRE m.movie_id IS UNIQUE;
CREATE CONSTRAINT user_name_unique IF NOT EXISTS FOR (u:User) REQUIRE u.user_name IS UNIQUE;
