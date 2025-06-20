-- setup
CREATE TABLE payment_users
(
    user_id bigint PRIMARY KEY,
    url text,
    login text,
    avatar_url text
);

SELECT create_distributed_table('payment_users','user_id');

SET CLIENT_ENCODING TO 'utf8';

-- COPY payment_users FROM PROGRAM
'curl https://raw.githubusercontent.com/MicrosoftDocs/mslearn-create-connect-postgresHyperscale/main/users.csv' WITH CSV;

SELECT COUNT(*) FROM payment_users;

select name, default_strategy from pg_dist_rebalance_strategy;
--Check Nodes Where Data Hasn't Been Distributed
-- This query helps identify worker nodes not holding any shard data:
SELECT nodename 
FROM pg_dist_node 
WHERE nodename NOT IN (
    SELECT DISTINCT nodename
    FROM pg_dist_placement AS placement,
         pg_dist_node AS node
    WHERE placement.groupid = node.groupid
      AND node.noderole = 'primary'
);
SELECT name, default_strategy 
FROM pg_dist_rebalance_strategy;



-- list available worker nodes that haven’t yet been assigned any shards.”

SELECT nodename 
FROM pg_dist_node 
WHERE nodename NOT IN (
  SELECT DISTINCT nodename
  FROM pg_dist_placement AS placement,
       pg_dist_node AS node
  WHERE placement.groupid = node.groupid
    AND node.noderole = 'primary'
);

-- Rebalancing the Shards
--Think of shards like containers of books, and worker nodes are the shelves. 
-- Initially, we had only a couple of shelves, so all the books were stacked on them. 
-- Now that we’ve installed more shelves, we want to rearrange the books so every shelf gets an equal number.
SELECT rebalance_table_shards(
  'payment_events', 
  rebalance_strategy := 'greedy'
);


-- Greedy strategy (default)
SELECT rebalance_table_shards('payment_users');

-- Shard-size aware strategy
SELECT rebalance_table_shards('payment_users', rebalance_strategy := 'by_shard_size');

-- Table-size aware strategy
SELECT rebalance_table_shards('payment_users', rebalance_strategy := 'by_table_size');

--Which one should I use?
--Greedy: Use when you just added workers and want quick balance.

--by_shard_size: Best when you have uneven shard sizes (e.g. some users generate much more data).

--by_table_size: Use for balancing entire large tables across the cluster.

--random: Only for testing purposes.

-- 4. How to View Current Shard Count
SELECT count(*) 
FROM pg_dist_shard 
WHERE logicalrelid = 'your_table'::regclass;
