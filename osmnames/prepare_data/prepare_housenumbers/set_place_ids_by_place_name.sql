CREATE INDEX IF NOT EXISTS osm_polygon_normalized_name ON osm_polygon(normalized_name); --&
CREATE INDEX IF NOT EXISTS osm_polygon_normalized_name_trgm ON osm_polygon USING GIN(normalized_name gin_trgm_ops); --&
CREATE INDEX IF NOT EXISTS osm_polygon_geometry ON osm_polygon USING GIST(geometry); --&
CREATE INDEX IF NOT EXISTS osm_point_normalized_name ON osm_point(normalized_name); --&
CREATE INDEX IF NOT EXISTS osm_point_normalized_name_trgm ON osm_point USING GIN(normalized_name gin_trgm_ops); --&
CREATE INDEX IF NOT EXISTS osm_point_geometry ON osm_point USING GIST(geometry); --&
CREATE INDEX IF NOT EXISTS osm_point_parent ON osm_point(parent_id); --&
CREATE INDEX IF NOT EXISTS osm_housenumber_geometry_center ON osm_housenumber USING GIST(geometry_center); --&

-- see https://www.postgresql.org/docs/9.6/static/pgtrgm.html for more information
UPDATE pg_settings SET setting = '0.5' WHERE name = 'pg_trgm.similarity_threshold';

DROP FUNCTION IF EXISTS best_matching_place(GEOMETRY, VARCHAR);
CREATE FUNCTION best_matching_place(geometry_in GEOMETRY, name_in VARCHAR)
RETURNS BIGINT AS $$
  SELECT osm_id
    FROM osm_polygon
    WHERE st_dwithin(geometry_in, geometry, 1000) -- added due better performance as some places are slightly out of border
          AND normalized_name % name_in
    ORDER BY similarity(normalized_name, name_in) DESC, place_rank DESC
    LIMIT 1;
$$ LANGUAGE 'sql' IMMUTABLE;

DROP FUNCTION IF EXISTS best_matching_point_place(GEOMETRY, VARCHAR);
CREATE FUNCTION best_matching_point_place(geometry_in GEOMETRY, name_in VARCHAR)
    RETURNS BIGINT AS $$
SELECT point.osm_id
FROM osm_point point
JOIN parent_polygons parent ON (ST_Within(geometry_in, parent.geometry) AND point.parent_id = parent.id)
WHERE point.normalized_name % name_in
ORDER BY similarity(point.normalized_name, name_in) DESC, ST_Distance(geometry_in, point.geometry)
LIMIT 1;
$$ LANGUAGE 'sql' IMMUTABLE;

DROP FUNCTION IF EXISTS street_from_parent(BIGINT);
CREATE FUNCTION street_from_parent(id_in BIGINT)
    RETURNS BIGINT AS $$
SELECT osm_id
FROM osm_polygon
WHERE id = id_in
LIMIT 1;
$$ LANGUAGE 'sql' IMMUTABLE;

-- set street id by best matching parent polygon
UPDATE osm_housenumber
  SET street_id = best_matching_place(geometry_center, normalized_place)
  WHERE street_id IS NULL
        AND normalized_place <> '';

-- set street id by closest point within same region with similar name
UPDATE osm_housenumber
SET street_id = best_matching_point_place(geometry_center, normalized_place)
WHERE street_id IS NULL
  AND normalized_place <> '';

-- Fallback set street id by parent polygon
UPDATE osm_housenumber
SET street_id = street_from_parent(parent_id)
WHERE street_id IS NULL
  AND normalized_place <> '';

DROP INDEX osm_polygon_normalized_name; --&
DROP INDEX osm_polygon_normalized_name_trgm; --&
DROP INDEX osm_housenumber_geometry_center; --&
