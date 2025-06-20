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
SELECT set_config('app.current_tenant', '100', false);

-- Step 6: Query as if filtered
SELECT * FROM customers;
SELECT * FROM invoices;
