// Import the 1,000,209 CSV rows in batches of 10,000 rows (CALL ... IN TRANSACTIONS,
// which replaces the deprecated USING PERIODIC COMMIT). MERGE makes the import idempotent:
// running it twice creates no duplicate nodes or relationships.
// Original run: 9,642 nodes and 1,003,393 relationships created in about 40 s.
//
// CALL ... IN TRANSACTIONS must run in an implicit (auto-commit) transaction: cypher-shell
// does this by default; in Neo4j Browser, prefix the query with ":auto".
// CALL (row) { ... } is the variable scope syntax of Neo4j 5.23+. The original run used
// CALL { WITH row ... }, which still works but is deprecated.

LOAD CSV WITH HEADERS FROM 'file:///MovieLens_Cleaned.csv' AS row FIELDTERMINATOR ';'
CALL (row) {
    MERGE (m:Movie {movie_id: toInteger(row.movie_id)})
    ON CREATE SET m.title = row.movie_title

    MERGE (o:Occupation {name: row.occupation})

    MERGE (u:User {user_name: row.user_name})
    ON CREATE SET u.age = toInteger(row.age), u.gender = row.gender

    MERGE (u)-[:WORKS_AS]->(o)
    MERGE (u)-[r:RATED]->(m)
    ON CREATE SET r.rating = toInteger(row.rating), r.timestamp_val = toInteger(row.timestamp_val)
} IN TRANSACTIONS OF 10000 ROWS;
