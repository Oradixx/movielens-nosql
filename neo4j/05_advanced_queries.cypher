// Advanced queries: APOC path expansion, KNN-style recommendation, shortest path.

// H1. Subgraph expansion with APOC (plugin enabled in docker-compose.yml)
// Business need: professions in a user's extended network, up to 3 hops through shared movies.
MATCH (u:User {user_name: 'Barry Erin'})
CALL apoc.path.subgraphNodes(u, {
    relationshipFilter: "RATED",
    minLevel: 1,
    maxLevel: 3
}) YIELD node
WITH node WHERE 'User' IN labels(node) AND node.user_name <> 'Barry Erin'
MATCH (node)-[:WORKS_AS]->(o:Occupation)
RETURN o.name AS Network_Occupation, COUNT(node) AS People_Count
ORDER BY People_Count DESC
LIMIT 5;

// H2. K-nearest neighbours collaborative filtering
// Business need: recommendations from the 50 users who share the most liked movies (4+ stars)
// with the target, weighted by their ratings. The WITH ... LIMIT 50 step keeps the
// traversal small instead of expanding every path at once.
MATCH (target:User {user_name: 'Barry Erin'})-[r1:RATED]->(m1:Movie)
WHERE r1.rating >= 4
MATCH (m1)<-[r2:RATED]-(other:User)
WHERE r2.rating >= 4 AND other <> target
WITH target, other, COUNT(m1) AS common_likes
ORDER BY common_likes DESC
LIMIT 50
MATCH (other)-[r3:RATED]->(m2:Movie)
WHERE r3.rating >= 4 AND NOT (target)-[:RATED]->(m2)
WITH m2, SUM(r3.rating) AS Weighted_Score, COUNT(other) AS Number_Of_Voters
WHERE Number_Of_Voters > 1
RETURN m2.title AS Recommended_Movie, Weighted_Score, Number_Of_Voters
ORDER BY Weighted_Score DESC
LIMIT 10;

// H3. Shortest path ("six degrees of separation") between two users through rated movies
MATCH (u1:User {user_name: 'Barry Erin'}), (u2:User {user_name: 'Lashandra Jessie'})
MATCH p = shortestPath((u1)-[:RATED*..6]-(u2))
RETURN p;
