-- Table and index creation
DROP TABLE IF EXISTS t1;
CREATE TABLE t1 (id int, name text);
CREATE INDEX t1_id_idx ON t1 (id);
INSERT INTO t1 SELECT generate_series(1, 5), md5(random()::text);

-- Sequential scan, Index scan, Index only scan
EXPLAIN ANALYZE SELECT * FROM t1; -- Seq Scan
EXPLAIN ANALYZE SELECT * FROM t1 WHERE id = 3; -- Index Scan
EXPLAIN ANALYZE SELECT id FROM t1 WHERE id = 3; -- Index Only Scan

-- Load more data
INSERT INTO t1 SELECT generate_series(6, 1000), md5(random()::text);

-- Changing the cost
SHOW random_page_cost;
EXPLAIN ANALYZE SELECT * FROM t1 WHERE id = 3; -- Index Scan
SET random_page_cost = 8;
EXPLAIN ANALYZE SELECT * FROM t1 WHERE id = 3; -- Changes the cost of the index scan



------------------------------------------------------------------------------------------------------------------------

-- Create new table and index
DROP TABLE IF EXISTS t2;
CREATE TABLE t2 (id int, name text);
CREATE INDEX t2_id_idx ON t2 (id);
INSERT INTO t2 SELECT generate_series(1, 5), md5(random()::text);

EXPLAIN SELECT * FROM t2; -- Seq Scan
EXPLAIN ANALYZE SELECT * FROM t2 WHERE id = 3; -- Index Scan
ANALYZE t2;
EXPLAIN ANALYZE SELECT * FROM t2 WHERE id = 3; -- Seq Scan
INSERT INTO t2 SELECT generate_series(6, 1000), md5(random()::text);
EXPLAIN ANALYZE SELECT * FROM t2 WHERE id = 3; -- Seq Scan
ANALYZE t2;
EXPLAIN ANALYZE SELECT * FROM t2 WHERE id = 3; -- Index Scan