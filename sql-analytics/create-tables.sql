-- create schema
CREATE SCHEMA s3_hive.test
WITH (location = 's3a://trino-analytics/');

-- create raw log table
CREATE TABLE IF NOT EXISTS s3_hive.test.raw_logs (
     log VARCHAR,
     ip VARCHAR,
     timestamp TIMESTAMP,
     request VARCHAR,
     user_agent VARCHAR
)
WITH (
    format = 'TEXTFILE',
    external_location = 's3://trino-analytics/logs/'
);

-- transform raw data and partition by date
DROP TABLE IF EXISTS s3_hive.test.transformed_logs;
CREATE TABLE IF NOT EXISTS s3_hive.test.transformed_logs
WITH (
    format = 'PARQUET',
    partitioned_by = ARRAY['date']
) AS
SELECT
    split_part(log, ' ', 1) AS ip,
    split_part(split_part(log, '"', 2), '"', 1) AS request,
    CASE
        WHEN length(split_part(split_part(log, '"', 6), '"', 1)) = 0 THEN NULL
        ELSE split_part(split_part(log, '"', 6), '"', 1)
        END AS user_agent,
    split_part(split_part(log, '[', 2), ' ', 1) AS date  -- Ensure `date` is the last column
FROM s3_hive.test.raw_logs;

--------- VIEWS ---------

-- Daily count
CREATE OR REPLACE VIEW s3_hive.test.daily_top_5_ips AS
SELECT
    date,
    ip,
    COUNT(*) AS request_count
FROM s3_hive.test.transformed_logs
GROUP BY date, ip
ORDER BY date, request_count DESC
LIMIT 5;

SELECT * FROM s3_hive.test.daily_top_5_ips;


-- Weekly count
CREATE OR REPLACE VIEW s3_hive.test.weekly_top_5_ips AS
SELECT
    date_trunc('week', CAST(date_parse(date, '%d/%b/%Y:%H:%i:%s') AS DATE)) AS week,
    ip,
    COUNT(*) AS request_count
FROM s3_hive.test.transformed_logs
GROUP BY date_trunc('week', CAST(date_parse(date, '%d/%b/%Y:%H:%i:%s') AS DATE)), ip
ORDER BY week, request_count DESC
LIMIT 5;

SELECT * FROM s3_hive.test.weekly_top_5_ips;


-- Daily users
CREATE OR REPLACE VIEW s3_hive.test.daily_top_5_devices AS
SELECT
    date,
    user_agent,
    COUNT(*) AS usage_count
FROM s3_hive.test.transformed_logs
WHERE user_agent IS NOT NULL
GROUP BY date, user_agent
ORDER BY date, usage_count DESC
LIMIT 5;

SELECT * FROM s3_hive.test.daily_top_5_devices;


-- Weekly users
CREATE OR REPLACE VIEW s3_hive.test.weekly_top_5_devices AS
SELECT
    date_trunc('week', CAST(date_parse(date, '%d/%b/%Y:%H:%i:%s') AS DATE)) AS week,
    user_agent,
    COUNT(*) AS usage_count
FROM s3_hive.test.transformed_logs
WHERE user_agent IS NOT NULL
GROUP BY date_trunc('week', CAST(date_parse(date, '%d/%b/%Y:%H:%i:%s') AS DATE)), user_agent
ORDER BY week, usage_count DESC
LIMIT 5;

SELECT * FROM s3_hive.test.weekly_top_5_devices;