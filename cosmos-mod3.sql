select * from pg_available_extensions


-- . Applying PostgreSQL Extensions
-- postgis for Geospatial Data
-- Enable extension
SELECT create_extension('postgis');

-- Add geospatial column
ALTER TABLE payment_events ADD COLUMN location geometry;

-- Insert sample location
UPDATE payment_events
SET location = ST_GeomFromText('POINT(-122.33 47.60)', 4326)
WHERE event_id = 1;

-- pgcron
-- Enable cron extension
SELECT create_extension('pg_cron');

-- Rollup table
CREATE TABLE event_rollups (
  user_id bigint,
  event_type text,
  event_count bigint,
  rollup_time timestamptz
);

-- Function to roll up events
CREATE OR REPLACE FUNCTION rollup_events(start_time timestamptz, end_time timestamptz)
RETURNS void AS $$
BEGIN
  INSERT INTO event_rollups
  SELECT user_id, event_type, COUNT(*) AS event_count, now()
  FROM payment_events
  WHERE created_at BETWEEN start_time AND end_time
  GROUP BY user_id, event_type;
END;
$$ LANGUAGE plpgsql;

-- Schedule it to run every hour
SELECT cron.schedule('rollup_job', '0 * * * *', $$SELECT rollup_events(now() - interval '1 hour', now());$$);


-- Enable extension
SELECT create_extension('azure_storage');

-- Register storage account
SELECT azure_storage.account_add(
  'xx',
  'xx'
);

-- Preview blob container contents
SELECT * FROM azure_storage_list('goofystgdemo3u947', 'images');

-- Load CSV data into distributed table
COPY payment_users FROM PROGRAM
  'curl https://goofystgdemo3u947.blob.core.windows.net/images/events.csv' WITH CSV;

COPY payment_events FROM PROGRAM
  'curl https://goofystgdemo3u947.blob.core.windows.net/images/events.csv' WITH CSV;
