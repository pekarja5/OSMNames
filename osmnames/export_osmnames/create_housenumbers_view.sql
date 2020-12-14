DROP MATERIALIZED VIEW IF EXISTS mv_housenumbers;
CREATE MATERIALIZED VIEW mv_housenumbers AS
SELECT
  osm_id,
  abs(street_id)::VARCHAR AS street_id,
  CASE WHEN street IS NOT NULL AND street != '' THEN street ELSE place END AS street,
  housenumber,
  round(ST_X(ST_Centroid(ST_Transform(geometry, 4326)))::numeric, 5) AS lon,
  round(ST_Y(ST_Centroid(ST_Transform(geometry, 4326)))::numeric, 5) AS lat
FROM osm_housenumber
WHERE street_id IS NOT NULL;
