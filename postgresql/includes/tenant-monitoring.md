---
ms.service: azure-cosmos-db
ms.subservice: postgresql
ms.topic: include
ms.date: 08/23/2024
---

When you enable this feature, accounting is activated for SQL commands such as `INSERT`, `UPDATE`, `DELETE`, and `SELECT`. This accounting is specifically designed for a `single tenant`. A query qualifies to be a single tenant query, if the query planner can restrict the query to a single shard or single tenant.
