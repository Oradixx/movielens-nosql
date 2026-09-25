// Simple queries: traversal, filtering and basic aggregation.

// S1. Multi-node traversal and filtering on both nodes
// Business need: young female artists, for targeted advertising.
MATCH (u:User)-[:WORKS_AS]->(o:Occupation)
WHERE o.name = 'artist' AND u.gender = 'F' AND u.age < 30
RETURN u.user_name, u.age, o.name
LIMIT 10;

// S2. String search and sorting
// Business need: every movie of the "Star Wars" franchise (CONTAINS is case-sensitive).
MATCH (m:Movie)
WHERE m.title CONTAINS 'Star Wars'
RETURN m.title, m.movie_id
ORDER BY m.title ASC;

// S3. Filtering on a relationship property
// Business need: the latest 5-star movies of one user.
MATCH (u:User {user_name: 'Barry Erin'})-[r:RATED]->(m:Movie)
WHERE r.rating = 5
RETURN m.title, r.timestamp_val
ORDER BY r.timestamp_val DESC
LIMIT 10;

// S4. Aggregation with implicit grouping (the grouping key is o.name)
// Business need: user base by profession.
MATCH (u:User)-[:WORKS_AS]->(o:Occupation)
RETURN o.name AS Profession, COUNT(u) AS TotalUsers
ORDER BY TotalUsers DESC
LIMIT 5;

// S5. 3-hop pattern: Occupation <- User -> Movie
// Business need: which professions are the biggest fans (5 stars) of "Pulp Fiction".
MATCH (o:Occupation)<-[:WORKS_AS]-(u:User)-[r:RATED]->(m:Movie {title: 'Pulp Fiction (1994)'})
WHERE r.rating = 5
RETURN o.name AS Profession, COUNT(u) AS HardcoreFans
ORDER BY HardcoreFans DESC
LIMIT 5;

// S6. WITH pipeline: filter on an aggregate (like SQL HAVING)
// Business need: blockbusters with more than 2,000 ratings.
MATCH (u:User)-[r:RATED]->(m:Movie)
WITH m, COUNT(r) AS total_ratings
WHERE total_ratings > 2000
RETURN m.title, total_ratings
ORDER BY total_ratings DESC;
