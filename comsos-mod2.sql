-- Assuming citus extension is already enabled

CREATE TABLE tenant_orders (
    tenant_id INT,
    order_id INT PRIMARY KEY,
    amount FLOAT,
    created_at TIMESTAMPTZ
);

-- Distribute by tenant_id
SELECT create_distributed_table('tenant_orders', 'tenant_id');


-- Load Data
\COPY tenant_orders(tenant_id, order_id, amount, created_at) FROM 'tenant_orders_module2.csv' WITH CSV HEADER;


-- Step 3: Query Coordinator Metadata
-- List all distributed tables
SELECT * FROM citus_tables;

-- See distribution method for tenant_orders
SELECT * FROM pg_dist_partition WHERE logical_relid = 'tenant_orders'::regclass;

-- View shards and node mapping
SELECT * FROM pg_dist_shard;
SELECT * FROM pg_dist_node;




-- Step 4: Run Distributed Queries
-- Standard distributed query
SELECT tenant_id, COUNT(*) AS total_orders, AVG(amount) AS avg_amount
FROM tenant_orders
GROUP BY tenant_id;

-- Filter by tenant (accessing single shard)
SELECT * FROM tenant_orders WHERE tenant_id = 202;


-- Step 5- Step 5: Query Anti-pattern Example
-- Anti-pattern: Broadcast join (joins not using the distribution column)
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    name TEXT
);
-- No distribution here (small lookup = reference table)
SELECT create_reference_table('products');

-- This join may be inefficient if not properly optimized
SELECT t.tenant_id, t.amount, p.name
FROM tenant_orders t
JOIN products p ON p.product_id = t.order_id;

--❗ Avoid joins that don't use the distribution column — they cause cross-node data movement.




-- 1. Users Table
-- DROP TABLE payment_users CASCADE;
CREATE TABLE payment_users (
    user_id bigint PRIMARY KEY,
    url text,
    login text,
    avatar_url text
);

-- DROP TABLE payment_events CASCADE;
CREATE TABLE payment_events (
    event_id bigint,
    event_type text,
    user_id bigint,
    merchant_id bigint,
    event_details jsonb,
    created_at timestamp,
    -- Create a compound primary key so that user_id can be set as the distribution column
    PRIMARY KEY (event_id, user_id)
);


-- 3. Event Types
CREATE TABLE event_types (
    event_type_id bigINT PRIMARY KEY,
    event_type TEXT
);

-- 4. Merchants
-- DROP TABLE payment_merchants CASCADE;
CREATE TABLE payment_merchants (
    merchant_id bigint PRIMARY KEY,
    name text,
    url text
);



SELECT create_distributed_table('payment_users', 'user_id');
SELECT create_distributed_table('payment_events', 'user_id');

SELECT create_reference_table('payments_merchants')

COPY payment_users
FROM PROGRAM 'curl https://raw.githubusercontent.com/pushkar72/cosmos-postgre/refs/heads/main/mod2-data/users.csv'
WITH (FORMAT csv, HEADER true);



CREATE TABLE user_events (
    user_id bigint,
    user_login text,
    event_type text,
    event_count bigint
);

INSERT INTO user_events
SELECT e.user_id, login, event_type, COUNT(event_id)
FROM payment_events AS e
INNER JOIN payment_users AS u ON e.user_id = u.user_id
GROUP BY e.user_id, login, event_type;


--table metadata
select * from citus_tables
-- get nodes info
 select * from pg_dist_node;

-- data skew, ensure all nodes are filling data evenly so performance is not impacted
select 
table_name,distribution_column,table_size 
from citus_tables 
WHERE table_name= '' ::regclass

--To inspect shard metadata for payment_events:

SELECT count(*) FROM pg_dist_shard WHERE logicalrelid = 'payment_users'::regclass
LIMIT 5;

--To check shard distribution size for payment_users:
SELECT shardid,
       shard_name,
       shard_size
FROM citus_shards
WHERE table_name = 'payment_users'::regclass
LIMIT 10;



--This query identifies the primary node placement for a specific shard of the payment_users table where the distribution column value is 5

SELECT shardid,
       nodename,
       placementid
FROM pg_dist_placement AS p,
     pg_dist_node AS n
WHERE p.groupid = n.groupid
  AND n.noderole = 'primary'
  AND shardid = (
      SELECT get_shard_id_for_distribution_column('payment_users', 3545)
  );

  -- user 3545

  -- manually rebalance
  select rebalance_table_shards('table_name');

  -- monitor active query               
  SELECT pid, query, state
FROM citus_stat_activity
WHERE state != 'idle';

-- long running query
SELECT
    pid,
    now() - pg_stat_activity.query_start AS duration,
    usename,
    state,
    query
FROM
    pg_stat_activity
WHERE
    state = 'active'
    AND now() - pg_stat_activity.query_start > interval '5 minutes'
ORDER BY
    duration DESC;

-- more queries
-- https://learn.microsoft.com/en-us/azure/cosmos-db/postgresql/howto-useful-diagnostic-queries







-- join & explain
EXPLAIN verbose
SELECT login, event_id
FROM payment_events AS e
LEFT JOIN payment_users u ON e.user_id = u.user_id;


-- repartitions joins  accross non distributed columns
-- Undistribute the table if it was a reference or incorrectly distributed
SELECT undistribute_table('payment_merchants');

-- Recreate it as a distributed table using 'merchant_id' as the distribution column
SELECT create_distributed_table('payment_merchants', 'merchant_id');


-- cross node joins are disabled

-- join to show error
SELECT event_type,
       event_id
FROM   payment_events AS e
       inner JOIN payment_merchants m
       ON e.merchant_id = m.merchant_id
LIMIT  5;


-- enable repartition
set citus.enable_repartition_joins to off;;


-- 
https://learn.microsoft.com/en-us/azure/cosmos-db/postgresql/howto-useful-diagnostic-queries