UPDATE osm_housenumber SET normalized_street = normalize_string(street); --&
UPDATE osm_housenumber SET normalized_place = normalize_string(place); --&
UPDATE osm_linestring SET normalized_name = normalize_string(name); --&
UPDATE osm_polygon SET normalized_name = normalize_string(name); --&
