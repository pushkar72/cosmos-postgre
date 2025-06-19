
-- =====================================================
-- ✅ Citus Cheat Sheet: Common Functions for Cosmos DB
-- =====================================================

-- 🟡 Table Distribution
SELECT create_distributed_table('orders', 'user_id');
SELECT create_reference_table('countries');
SELECT undistribute_table('orders');
SELECT citus_schema_distribute('training');
SELECT citus_schema_undistribute('training');
SELECT truncate_local_data_after_distributing_table('orders');

-- 🟡 Shard Inspection
SELECT * FROM pg_dist_shard;  -- View all shards
SELECT * FROM pg_dist_node;   -- View all nodes
SELECT * FROM pg_dist_shard_placement;  -- Node-shard mapping

-- 🔍 Distribution Metadata
SELECT column_to_column_name('orders'::regclass, partkey)
FROM pg_dist_partition;

SELECT get_shard_id_for_distribution_column('orders', 101); -- Sample user_id
SELECT citus_relation_size('orders'); -- Total size across shards

-- 🔄 Rebalancing Shards
SELECT rebalance_table_shards('orders');
SELECT get_rebalance_table_shards_plan('orders');
SELECT get_rebalance_progress();

-- 🔧 Shard Repair (Advanced)
SELECT citus_move_shard_placement(...);
SELECT citus_copy_shard_placement(...);

-- 🧠 Distributed Functions (Parallel UDF execution)
SELECT create_distributed_function('my_custom_function');

-- 👥 Multi-tenant Optimization
SELECT isolate_tenant_to_new_shard('tenant_orders', 301);

-- 🔁 Altering Distribution (requires downtime)
SELECT alter_distributed_table('orders', new_distribution_column := 'new_col', shard_count := 16);

-- 📊 Monitor
SELECT * FROM pg_stat_statements;
