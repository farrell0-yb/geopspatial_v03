

-- ============================================================================
--
-- Purpose  : Define a custom 'geometry' composite type for YugabyteDB YSQL.
--
--            This is a lightweight geometry type modeled after PostGIS's
--            geometry column type, but implemented as a pure SQL composite
--            type requiring no C extensions.
--
--            Internally it stores parallel arrays of lon[] and lat[] vertices.
--            A point is a single-element array.  A polygon is 3+ vertices
--            listed in order (CW or CCW); explicit closing is not required.
--
-- Conventions:
--   X = longitude,  Y = latitude   (matches PostGIS ST_X / ST_Y)
--
-- ============================================================================

-- Drop dependents first (functions that use the type) so the
-- CREATE TYPE can run cleanly on repeated executions.
--
DROP TYPE IF EXISTS geometry CASCADE;

CREATE TYPE geometry AS (
   lon   double precision[],
   lat   double precision[]
);


-- ============================================================================
-- Constructor helpers
-- ============================================================================

-- ------------------------------------------------------------
-- lm_make_point(lon, lat)
--   Creates a geometry representing a single point.
--
-- Example:
--   SELECT lm_make_point(-111.97, 40.52);
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION lm_make_point(
   p_lon double precision,
   p_lat double precision
)
RETURNS geometry
LANGUAGE sql IMMUTABLE
AS $$
   SELECT ROW(ARRAY[p_lon], ARRAY[p_lat])::geometry;
$$;


-- ------------------------------------------------------------
-- lm_make_polygon(lon[], lat[])
--   Creates a geometry from parallel vertex arrays.
--
-- Example:
--   SELECT lm_make_polygon(
--       ARRAY[-112.0, -111.9, -111.9, -112.0],
--       ARRAY[40.5,   40.5,   40.55,  40.55]
--   );
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION lm_make_polygon(
   p_lon double precision[],
   p_lat double precision[]
)
RETURNS geometry
LANGUAGE plpgsql IMMUTABLE
AS $$
BEGIN
   IF coalesce(array_length(p_lon, 1), 0) < 1 THEN
      RAISE EXCEPTION 'lm_make_polygon: lon array must not be empty';
   END IF;
   IF array_length(p_lon, 1) <> coalesce(array_length(p_lat, 1), 0) THEN
      RAISE EXCEPTION 'lm_make_polygon: lon[] and lat[] must be same length';
   END IF;
   RETURN ROW(p_lon, p_lat)::geometry;
END;
$$;


-- ------------------------------------------------------------
-- lm_make_bbox(lon_min, lat_min, lon_max, lat_max)
--   Creates a geometry rectangle from bounding-box corners.
--   Vertex order: SW, SE, NE, NW  (counter-clockwise).
--
-- Example:
--   SELECT lm_make_bbox(-112.0, 40.5, -111.9, 40.55);
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION lm_make_bbox(
   p_lon_min double precision,
   p_lat_min double precision,
   p_lon_max double precision,
   p_lat_max double precision
)
RETURNS geometry
LANGUAGE sql IMMUTABLE
AS $$
   SELECT ROW(
      ARRAY[p_lon_min, p_lon_max, p_lon_max, p_lon_min],
      ARRAY[p_lat_min, p_lat_min, p_lat_max, p_lat_max]
   )::geometry;
$$;




