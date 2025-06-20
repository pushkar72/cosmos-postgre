CREATE TABLE public.employees (
    id SERIAL PRIMARY KEY,
    name TEXT,
    department TEXT,
    salary NUMERIC
);

INSERT INTO employees (name, department, salary)
SELECT
    'Emp_' || i,
    'Dept_' || (i % 5),
    50000 + (random() * 10000)::int
FROM generate_series(1, 10000) AS s(i);



DELETE FROM employees
WHERE id <= 7000;


-- check if table needs vaccum
SELECT
    relname AS table_name,
    n_live_tup AS live_rows,
    n_dead_tup AS dead_rows,
    last_vacuum,
    last_autovacuum,
    vacuum_count,
    autovacuum_count
FROM
    pg_stat_user_tables
WHERE
    relname = 'employees';  



SHOW autovacuum;
SHOW autovacuum_vacuum_threshold;
SHOW autovacuum_vacuum_scale_factor;


VACUUM ANALYZE employees;


VACUUM FULL employees;


ANALYZE employees;



SELECT relname AS table_name,
       n_live_tup AS live_rows,
       n_dead_tup AS dead_rows,
       last_vacuum,
       last_autovacuum,
       last_analyze,
       last_autoanalyze
FROM pg_stat_user_tables
WHERE relname = 'employees';

SET log_autovacuum_min_duration = 0; -- Logs all autovacuums




-- estimate bloat
SELECT
    schemaname,
    relname AS table_name,
    n_live_tup,
    n_dead_tup,
    ROUND(100.0 * n_dead_tup / (n_live_tup + n_dead_tup), 2) AS dead_pct
FROM
    pg_stat_user_tables
WHERE
    n_dead_tup > 0
ORDER BY
    dead_pct DESC;
--If dead_pct is high (e.g., >20–30%), it's a sign to manually vacuum.
VACUUM ANALYZE your_table_name;

