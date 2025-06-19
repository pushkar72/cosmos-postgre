
-- ===========================================
-- 🌐 Woodgrove Bank Schema: Side-by-Side SQL
-- BEFORE vs AFTER Distribution (for Citus)
-- ===========================================

-- ┌─────────────────────────────┐
-- │     BEFORE DISTRIBUTION     │
-- └─────────────────────────────┘

-- 1. Users Table
CREATE TABLE payment_users (
    user_id bigINT PRIMARY KEY,
    login TEXT,
    url TEXT,
    avatar_url TEXT
);

-- 2. Events Table
CREATE TABLE payment_events (
    event_id bigINT ,
    event_type_id bigINT References event_types(event_type_id),
    user_id bigINT,
    merchant_id bigINT References payment_merchants(merchant_id),
    event_details TEXT,
    created_at TIMESTAMP
) partition by range(created_at) ;

-- 3. Event Types
CREATE TABLE event_types (
    event_type_id bigINT PRIMARY KEY,
    event_type TEXT
);

-- 4. Merchants
CREATE TABLE payment_merchants (
    merchant_id bigINT PRIMARY KEY,
    merchant_name TEXT,
    url TEXT
);

SELECT table_name, citus_table_type, distribution_column, colocation_id
FROM public.citus_tables;

-- ┌─────────────────────────────┐
-- │     AFTER DISTRIBUTION      │
-- └─────────────────────────────┘
CREATE TABLE payment_events (
    event_id bigINT ,
    event_type_id BIGINT,
    user_id bigINT,
    merchant_id BIGINT ,
    event_details TEXT,
    created_at TIMESTAMP,
    PRIMARY KEY (event_id,user_id)
);
-- Enable Citus
CREATE EXTENSION IF NOT EXISTS citus;

-- Distribute Users Table by user_id
SELECT create_distributed_table('payment_users', 'user_id');

-- Modify Events Table for Citus (PK must include distribution column)
ALTER TABLE payment_events DROP CONSTRAINT payment_events_pkey;
ALTER TABLE payment_events ADD PRIMARY KEY (user_id, event_id);
SELECT create_distributed_table('payment_events', 'user_id');

-- Convert Lookup Tables to Reference
SELECT create_reference_table('event_types');
SELECT create_reference_table('payment_merchants');

-- Optional Indexes
CREATE INDEX idx_event_user ON payment_events(user_id);
CREATE INDEX idx_event_date ON payment_events(created_at);

-- ┌─────────────────────────────┐
-- │     DATA INGESTION          │
-- └─────────────────────────────┘

-- Load sample data using:
-- \COPY payment_users FROM 'payment_users.csv' WITH CSV HEADER;
-- \COPY payment_events FROM 'payment_events.csv' WITH CSV HEADER;
-- \COPY event_types FROM 'event_types.csv' WITH CSV HEADER;
-- \COPY payment_merchants FROM 'payment_merchants.csv' WITH CSV HEADER;


--Partition time series
select create_time_partitions(
    table_name:='payment_events',
    partition_interval:= '5 days',
    start_at:=now()-'2 months',
    end_at:=now()+ '6 months'

)


SELECT update_distributed_table_colocation('payment_merchants', colocate_with => 'none');
