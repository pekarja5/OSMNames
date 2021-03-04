ALTER TABLE osm_linestring ADD parent_id BIGINT,
                           ADD place_rank INTEGER,
                           ADD alternative_names TEXT,
                           ADD geometry_center GEOMETRY DEFAULT(ST_Point(0,0)),
                           ADD merged_into BIGINT,
                           ADD normalized_name TEXT;

ALTER TABLE osm_polygon ADD parent_id BIGINT,
                        ADD place_rank INTEGER,
                        ADD alternative_names TEXT,
                        ADD country_code VARCHAR(2),
                        ADD normalized_name TEXT,
                        ADD merged_osm_id BIGINT;

ALTER TABLE osm_point ADD parent_id BIGINT,
                      ADD place_rank INTEGER,
                      ADD alternative_names TEXT,
                      ADD merged Boolean DEFAULT(false);

ALTER TABLE osm_housenumber ADD parent_id BIGINT,
                            ADD street_id BIGINT,
                            ADD geometry_center GEOMETRY DEFAULT(ST_Point(0,0)),
                            ADD normalized_place TEXT,
                            ADD normalized_street TEXT;


ALTER TABLE osm_point ADD normalized_name TEXT;
