---
title: Nodes – Azure Cosmos DB for PostgreSQL
description: Learn about the types of nodes and tables in a cluster.
ms.author: jonels
author: jonels-msft
ms.service: azure-cosmos-db
ms.subservice: postgresql
ms.topic: concept-article
ms.date: 09/29/2023
---

# Nodes and tables in Azure Cosmos DB for PostgreSQL

[!INCLUDE [PostgreSQL](../includes/appliesto-postgresql.md)]

## Nodes

Azure Cosmos DB for PostgreSQL allows PostgreSQL
servers (called nodes) to coordinate with one another in a "shared nothing"
architecture. The nodes in a cluster collectively hold more data and use
more CPU cores than would be possible on a single server. The architecture also
allows the database to scale by adding more nodes to the cluster.

### Coordinator and workers

Every cluster has a coordinator node and multiple workers. Applications
send their queries to the coordinator node, which relays it to the relevant
workers and accumulates their results.

Azure Cosmos DB for PostgreSQL allows the database administrator to *distribute* tables and/or schemas,
storing different rows on different worker nodes. Distributed tables and/or schemas are the
key to Azure Cosmos DB for PostgreSQL performance. Failing to distribute tables and/or schemas leaves them entirely
on the coordinator node and can't take advantage of cross-machine parallelism.

For each query on distributed tables, the coordinator either routes it to a
single worker node, or parallelizes it across several depending on whether the
required data lives on a single node or multiple. With [schema-based sharding](concepts-sharding-models.md#schema-based-sharding), the coordinator routes the queries directly to the node that hosts the schema. In both schema-based sharding and [row-based sharding](concepts-sharding-models.md#row-based-sharding), the coordinator decides what
to do by consulting metadata tables. These tables track the DNS names and
health of worker nodes, and the distribution of data across nodes.

## Table types

There are five types of tables in a cluster, each
stored differently on nodes and used for different purposes.

### Type 1: Distributed tables

The first type, and most common, is distributed tables. They
appear to be normal tables to SQL statements, but they're horizontally
partitioned across worker nodes. What this means is that the rows
of the table are stored on different nodes, in fragment tables called
shards.

Azure Cosmos DB for PostgreSQL runs not only SQL but DDL statements throughout a cluster.
Changing the schema of a distributed table cascades to update
all the table's shards across workers.

#### Distribution column

Azure Cosmos DB for PostgreSQL uses algorithmic sharding to assign rows to shards. The assignment is made deterministically based on the value
of a table column called the distribution column. The cluster
administrator must designate this column when distributing a table.
Making the right choice is important for performance and functionality.

### Type 2: Reference tables

A reference table is a type of distributed table whose entire
contents are concentrated into a single shard. The shard is replicated on every worker. Queries on any worker can access the reference information locally, without the network overhead of requesting rows from another node. Reference tables have no distribution column
because there's no need to distinguish separate shards per row.

Reference tables are typically small and are used to store data that's
relevant to queries running on any worker node. An example is enumerated
values like order statuses or product categories.

### Type 3: Local tables

When you use Azure Cosmos DB for PostgreSQL, the coordinator node you connect to is a regular PostgreSQL database. You can create ordinary tables on the coordinator and choose not to shard them.

A good candidate for local tables would be small administrative tables that don't participate in join queries. An example is a `users` table for application sign-in and authentication.

### Type 4: Local managed tables

Azure Cosmos DB for PostgreSQL might automatically add local tables to metadata if a foreign key reference exists between a local table and a reference table. Additionally locally managed tables can be manually created by executing [create_reference_table](reference-functions.md#citus_add_local_table_to_metadata) citus_add_local_table_to_metadata function on regular local tables. Tables present in metadata are considered managed tables and can be queried from any node, Citus knows to route to the coordinator to obtain data from the local managed table. Such tables are displayed as local in [citus_tables](reference-metadata.md#distributed-tables-view) view.

### Type 5: Schema tables

With [schema-based sharding](concepts-sharding-models.md#schema-based-sharding) introduced in Citus 12.0, distributed schemas are automatically associated with individual colocation groups. Tables created in those schemas are automatically converted to colocated distributed tables without a shard key. Such tables are considered schema tables and are displayed as schema in [citus_tables](reference-metadata.md#distributed-tables-view) view.

## Shards

The previous section described how distributed tables are stored as shards on
worker nodes. This section discusses more technical details.

The `pg_dist_shard` metadata table on the coordinator contains a
row for each shard of each distributed table in the system. The row
matches a shard ID with a range of integers in a hash space
(shardminvalue, shardmaxvalue).

```sql
SELECT * from pg_dist_shard;
 logicalrelid  | shardid | shardstorage | shardminvalue | shardmaxvalue
---------------+---------+--------------+---------------+---------------
 github_events |  102026 | t            | 268435456     | 402653183
 github_events |  102027 | t            | 402653184     | 536870911
 github_events |  102028 | t            | 536870912     | 671088639
 github_events |  102029 | t            | 671088640     | 805306367
 (4 rows)
```

If the coordinator node wants to determine which shard holds a row of
`github_events`, it hashes the value of the distribution column in the
row. Then the node checks which shard\'s range contains the hashed value. The
ranges are defined so that the image of the hash function is their
disjoint union.

### Shard placements

Suppose that shard 102027 is associated with the row in question. The row
is read or written in a table called `github_events_102027` in one of
the workers. Which worker? That's determined entirely by the metadata
tables. The mapping of shard to worker is known as the shard placement.

The coordinator node
rewrites queries into fragments that refer to the specific tables
like `github_events_102027` and runs those fragments on the
appropriate workers. Here's an example of a query run behind the scenes to find the node holding shard ID 102027.

```sql
SELECT
    shardid,
    node.nodename,
    node.nodeport
FROM pg_dist_placement placement
JOIN pg_dist_node node
  ON placement.groupid = node.groupid
 AND node.noderole = 'primary'::noderole
WHERE shardid = 102027;
```

```output
┌─────────┬───────────┬──────────┐
│ shardid │ nodename  │ nodeport │
├─────────┼───────────┼──────────┤
│  102027 │ localhost │     5433 │
└─────────┴───────────┴──────────┘
```

## Next steps

- [Determine your application's type](howto-app-type.md) to prepare for data modeling
- Inspect shards and placements with [useful diagnostic queries](howto-useful-diagnostic-queries.md).
