CREATE TABLE customers (
    customer_id bigint,
    tenant_id int,
    name text,
    PRIMARY KEY (customer_id, tenant_id)
);

SELECT create_distributed_table('customers', 'tenant_id');

-- Add row-level security
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

CREATE POLICY customer_policy
    ON customers
    USING (tenant_id = current_setting('app.current_tenant')::int);



-- FS Demo

-- Step 1: Create tables
CREATE TABLE customers (
    customer_id BIGINT,
    tenant_id INT,
    name TEXT,
    PRIMARY KEY (customer_id, tenant_id)
);

CREATE TABLE invoices (
    invoice_id BIGINT,
    customer_id BIGINT,
    tenant_id INT,
    amount NUMERIC,
    due_date DATE,
    PRIMARY KEY (invoice_id, tenant_id)
);

-- Step 2: Distribute tables on tenant_id
SELECT create_distributed_table('customers', 'tenant_id');
SELECT create_distributed_table('invoices', 'tenant_id');

-- Step 3: Import CSVs using psql \copy or your .NET app
-- Example psql command:
-- \copy customers FROM 'customers_demo.csv' WITH CSV HEADER;
-- \copy invoices FROM 'invoices_demo.csv' WITH CSV HEADER;

-- Step 4: Add row-level security
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_policy_customers ON customers
  USING (tenant_id = current_setting('app.current_tenant')::int);

CREATE POLICY tenant_policy_invoices ON invoices
  USING (tenant_id = current_setting('app.current_tenant')::int);

-- Step 5: Set tenant context for demo
SELECT set_config('app.tenant_id', '101', false);

-- Step 6: Query as if filtered
SELECT * FROM customers;
SELECT * FROM invoices;







-- RLS Setup Script for PostgreSQL / Azure Cosmos DB for PostgreSQL

-- Step 1: Create the multi-tenant table
CREATE TABLE orders (
    order_id BIGINT,
    tenant_id bigINT,
    item TEXT,
    amount DECIMAL,
    PRIMARY KEY (order_id, tenant_id)
);

-- Step 2: Insert records for multiple tenants
INSERT INTO orders (order_id, tenant_id, item, amount) VALUES
(1, 101, 'Laptop', 1200.00),
(2, 101, 'Mouse', 25.00),
(3, 102, 'Keyboard', 45.00),
(4, 102, 'Monitor', 200.00),
(5, 103, 'Tablet', 300.00);

-- Step 3: Enable Row-Level Security
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Step 4: Create a policy to allow access only to rows matching the session tenant_id
CREATE POLICY tenant_access_policy
  ON orders
  USING (tenant_id = current_setting('app.tenant_id')::bigint);

-- Step 5: Enforce the policy
ALTER TABLE orders FORCE ROW LEVEL SECURITY;

-- Step 6: Simulate tenant login - set tenant_id for session
-- This is typically set programmatically by your app
SET app.tenant_id = '101';

-- Step 7: Test RLS - you should see only tenant_id = 101 rows
SELECT * FROM orders;

-- You can change the tenant_id to test isolation:
-- SET app.tenant_id = '102';
-- SELECT * FROM orders;


--  Even Admins Must Define Bypass Policies
-- So no one—by default—can bypass policies unless granted by you

CREATE POLICY admin_bypass_policy
  ON orders
  TO admin_role
  USING (true); -- allows all rows
