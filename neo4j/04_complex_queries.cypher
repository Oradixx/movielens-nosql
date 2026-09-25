// Complex queries: collections, list slicing, map projections and list predicates.

// C1. Collaborative filtering (V-shaped pattern Movie <- User -> Movie)
// Business need: recommendations for people who loved "The Matrix".
MATCH (m1:Movie {title: 'Matrix, The (1999)'})<-[:RATED {rating: 5}]-(u:User)-[:RATED {rating: 5}]->(m2:Movie)
WHERE m1 <> m2
RETURN m2.title AS Recommended_Movie, COUNT(u) AS Fan_Overlap
ORDER BY Fan_Overlap DESC
LIMIT 10;

// C2. Ordered collections and list slicing
// Business need: top 3 five-star movies of each profession.
MATCH (o:Occupation)<-[:WORKS_AS]-(u:User)-[r:RATED]->(m:Movie)
WHERE r.rating = 5
WITH o, m, COUNT(r) AS ratingCount
ORDER BY ratingCount DESC
WITH o, collect(m.title)[0..3] AS Top_3_Movies
RETURN o.name AS Profession, Top_3_Movies
LIMIT 10;

// C3. Map projections: nested JSON-like documents
// Business need: export user profiles for an API or a document database (e.g. MongoDB).
MATCH (u:User)-[:WORKS_AS]->(o:Occupation)
WITH u, o LIMIT 5
MATCH (u)-[r:RATED]->(m:Movie)
WITH u, o, collect(m { .title, rating: r.rating })[0..3] AS movie_history
RETURN u {
    .user_name,
    .age,
    .gender,
    occupation: o.name,
    history: movie_history
} AS user_profile_json;

// C4. List predicate ALL()
// Business need: sci-fi fans who rated both classics, ranked by total activity.
MATCH (u:User)-[r:RATED]->(m:Movie)
WITH u, collect(m.title) AS watched_movies
WHERE ALL(movie IN [
    'Star Wars: Episode IV - A New Hope (1977)',
    'Blade Runner (1982)'
] WHERE movie IN watched_movies)
RETURN u.user_name, size(watched_movies) AS Total_Movies_Watched
ORDER BY Total_Movies_Watched DESC
LIMIT 10;
