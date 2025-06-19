-- Enable Citus extension
CREATE EXTENSION IF NOT EXISTS citus;
CREATE SCHEMA IF NOT EXISTS cdemo;
-- Reference table: replicated to all worker nodes
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    name TEXT
);

-- Distributed table: sharded by user_id
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    user_id INT,
    amount FLOAT,
    created_at TIMESTAMPTZ
);
SELECT create_distributed_table('orders', 'user_id');


-- Step 2: Load Sample Data
-- Reference table
\COPY users(user_id, name) FROM 'users.csv' WITH CSV HEADER;

-- Distributed table
\COPY orders(order_id, user_id, amount, created_at) FROM 'orders.csv' WITH CSV HEADER;


-- Step 3: Query and Verify Data
SELECT * FROM users;
SELECT * FROM orders ORDER BY created_at DESC LIMIT 5;



-- Step 4: Scaffolding for Partitioning
-- We’ll simulate a time-series IoT use case with sensor_data.
CREATE TABLE sensor_data (
    id INT,
    reading FLOAT,
    reading_time TIMESTAMPTZ
);
SELECT create_distributed_table('sensor_data', 'id');


\COPY sensor_data(id, reading, reading_time) FROM 'sensor_data.csv' WITH CSV HEADER;

-- Step 5: Alter Distributed Table (Scaffolding Changes)
-- This works — Citus supports DDL changes via coordinator node.
ALTER TABLE orders ADD COLUMN status TEXT DEFAULT 'Pending';


--  Step 6: Knowledge Check SQL (Optional Quiz Items)
-- Which tables are distributed?
SELECT * FROM citus_tables;

-- Where are shards located?
SELECT * FROM pg_dist_shard;




-- drop all
DO
$$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'cdemo'
    )
    LOOP
        EXECUTE format('DROP TABLE IF EXISTS cdemo.%I CASCADE;', r.tablename);
    END LOOP;
END
$$;

DROP SCHEMA schema_name CASCADE;
-- CASCADE drops all objects in the schema
-- Use RESTRICT instead to prevent deletion if schema is not empty


-- set default, switch

-- Set search path to a schema
SET search_path TO schema_name;

-- To use multiple schemas, prioritize by order
SET search_path TO schema1, schema2, public;

