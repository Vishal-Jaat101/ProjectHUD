-- ====================================================================
-- ProjectHUD Phase 3: Telemetry Warehouse & Accident Prediction Schema
-- Target: Google Cloud BigQuery
-- ====================================================================

CREATE SCHEMA IF NOT EXISTS `projecthud_telemetry`
OPTIONS (
  location = 'asia-south1', -- Mumbai / India region
  description = 'Anonymised rider probe events for accident prediction'
);

-- 1. Anonymised Raw Telemetry Ingestion Table
-- Partitioned daily by timestamp, clustered by road_segment_id and event_type
CREATE TABLE IF NOT EXISTS `projecthud_telemetry.telemetry_events`
(
  event_id STRING NOT NULL,
  timestamp TIMESTAMP NOT NULL,
  latitude FLOAT64 NOT NULL,
  longitude FLOAT64 NOT NULL,
  road_segment_id STRING NOT NULL,
  event_type STRING NOT NULL, -- 'harshBraking', 'suddenSwerve', 'overspeeding', 'nearMiss'
  speed_kmh FLOAT64 NOT NULL,
  acceleration_mss FLOAT64,
  gyroscope_dps FLOAT64,
  hour_of_day INT64 NOT NULL,
  day_of_week INT64 NOT NULL,
  weather_condition STRING
)
PARTITION BY DATE(timestamp)
CLUSTER BY road_segment_id, event_type
OPTIONS (
  description = 'Fleet probe sensor records. No personal identifiable information.'
);

-- 2. Aggregated Road Segment Features for Model Training
CREATE OR REPLACE VIEW `projecthud_telemetry.v_segment_hourly_features` AS
SELECT
  road_segment_id,
  hour_of_day,
  day_of_week,
  COUNT(1) AS total_probe_count,
  COUNTIF(event_type = 'harshBraking') AS harsh_braking_events,
  COUNTIF(event_type = 'suddenSwerve') AS sudden_swerve_events,
  COUNTIF(event_type = 'overspeeding') AS overspeeding_events,
  AVG(speed_kmh) AS avg_speed_kmh,
  MAX(speed_kmh) AS max_speed_kmh,
  STDDEV(speed_kmh) AS speed_variance,
  -- Crash vulnerability index derived from near-miss kinematics
  (COUNTIF(event_type = 'harshBraking') * 1.5 + 
   COUNTIF(event_type = 'suddenSwerve') * 2.0 + 
   COUNTIF(event_type = 'overspeeding') * 1.0) / GREATEST(COUNT(1), 1) AS raw_risk_index
FROM `projecthud_telemetry.telemetry_events`
WHERE timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)
GROUP BY road_segment_id, hour_of_day, day_of_week;

-- 3. BigQuery ML Accident Risk Model Training
CREATE OR REPLACE MODEL `projecthud_telemetry.accident_risk_model`
OPTIONS(
  model_type = 'BOOSTED_TREE_CLASSIFIER',
  input_label_cols = ['is_high_risk_incident'],
  max_iterations = 50,
  learn_rate = 0.1
) AS
SELECT
  hour_of_day,
  day_of_week,
  total_probe_count,
  harsh_braking_events,
  sudden_swerve_events,
  overspeeding_events,
  avg_speed_kmh,
  speed_variance,
  IF(raw_risk_index > 0.65, 1, 0) AS is_high_risk_incident
FROM `projecthud_telemetry.v_segment_hourly_features`;

-- 4. Materialized Segment Risk Scores (Synced to Firestore for App Lookups)
CREATE TABLE IF NOT EXISTS `projecthud_telemetry.road_segment_risk_scores`
(
  road_segment_id STRING NOT NULL,
  latitude FLOAT64 NOT NULL,
  longitude FLOAT64 NOT NULL,
  risk_score FLOAT64 NOT NULL, -- 0.0 to 1.0
  risk_level STRING NOT NULL,  -- 'low', 'medium', 'high', 'critical'
  peak_hours ARRAY<INT64>,
  last_updated TIMESTAMP NOT NULL
)
CLUSTER BY road_segment_id;
