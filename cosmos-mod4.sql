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
WHERE logicalrelid = 'payment_events'::regclass;

-- shard accross worker node for each table



--Demo

-- Check Which Table Data is on Which Worker Node
select 
	s.logicalrelid::regclass as table_name,
	s.shardid,
	n.nodename,
	n.nodeport,
	p.placementid
from pg_dist_shard s
join pg_dist_placement p using (shardid)
join pg_dist_node n on p.groupid=n.groupid
where logicalrelid ='public.payment_events'::regclass;


select 
	n.nodename,
	count(p.shardid)  as total_shards
from pg_dist_placement p
join pg_dist_node n on p.groupid=n.groupid
GROUP BY n.nodename
where logicalrelid ='public.payment_events'::regclass;

-- query to see disk size consumed by shards on worker nodes

select nodename,
    pg_size_pretty(SUM(s.shard_size_bytes)) as total_size,
    count(*) as shard_count
from
    citus_shards_size s
join
    pg_dist_node n on s.groupid=n.groupid
GROUP BY n.nodename;



















-- Get Total Shard Count for a Table
SELECT COUNT(*) AS shard_count
FROM pg_dist_shard
WHERE logicalrelid = 'your_table_name'::regclass;
--or
SELECT shardid FROM pg_dist_shard
WHERE logicalrelid = 'your_table_name'::regclass;



-- Manually Rebalance Data After Scaling (Re-shard)
--Add Worker Node (if not already done):
SELECT * FROM master_add_node('new-worker-host', 5432);

SELECT * FROM citus_shards_distribution;

-- Rebalance All Shards:
SELECT rebalance_table_shards();

-- for table
SELECT rebalance_table_shards('your_table_name');


--This will move shards across worker nodes to balance data based on size and count.







