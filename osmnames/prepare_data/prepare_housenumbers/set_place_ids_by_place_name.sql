CREATE INDEX IF NOT EXISTS osm_polygon_normalized_name ON osm_polygon(normalized_name); --&
CREATE INDEX IF NOT EXISTS osm_polygon_normalized_name_trgm ON osm_polygon USING GIN(normalized_name gin_trgm_ops); --&
CREATE INDEX IF NOT EXISTS osm_polygon_geometry ON osm_polygon USING GIST(geometry); --&
CREATE INDEX IF NOT EXISTS osm_housenumber_geometry_center ON osm_housenumber USING GIST(geometry_center); --&

-- see https://www.postgresql.org/docs/9.6/static/pgtrgm.html for more information
UPDATE pg_settings SET setting = '0.5' WHERE name = 'pg_trgm.similarity_threshold';

DROP FUNCTION IF EXISTS best_matching_place(GEOMETRY, VARCHAR);
CREATE FUNCTION best_matching_place(geometry_in GEOMETRY, name_in VARCHAR)
RETURNS BIGINT AS $$
  SELECT osm_id
    FROM osm_polygon
    WHERE st_dwithin(geometry_in, geometry, 1000) -- added due better performance
          AND normalized_name % name_in
    ORDER BY similarity(normalized_name, name_in) DESC, place_rank DESC
    LIMIT 1;
$$ LANGUAGE 'sql' IMMUTABLE;

-- set street id by best matching name within same parent
UPDATE osm_housenumber
  SET street_id = best_matching_place(geometry_center, normalized_place)
  WHERE street_id IS NULL
        AND normalized_place <> '';

DROP INDEX osm_polygon_normalized_name; --&
DROP INDEX osm_polygon_normalized_name_trgm; --&
DROP INDEX osm_housenumber_geometry_center; --&
