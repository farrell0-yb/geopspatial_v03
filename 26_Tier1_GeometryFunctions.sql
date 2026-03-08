-- ============================================================================
--
-- Tier 1 Geometry Functions  —  Quick Wins
--
-- Pure PL/pgSQL PostGIS equivalents for YugabyteDB YSQL.
-- No extensions required.
--
-- Requires : 10_CreateGeometryType.sql  (geometry type + constructors)
--            20_GeohashFunctions.sql    (point_in_polygon)
--            25_GeometryFunctions.sql   (lm_st_xmin/xmax/ymin/ymax, etc.)
--
-- Functions in this file:
--    1) lm_st_x             -> ST_X
--    2) lm_st_y             -> ST_Y
--    3) lm_st_npoints       -> ST_NPoints
--    4) lm_geometry_type    -> GeometryType
--    5) lm_st_geometrytype  -> ST_GeometryType
--    6) lm_st_startpoint    -> ST_StartPoint
--    7) lm_st_endpoint      -> ST_EndPoint
--    8) lm_st_pointn        -> ST_PointN
--    9) lm_st_isclosed      -> ST_IsClosed
--   10) lm_st_isempty       -> ST_IsEmpty
--   11) lm_st_envelope      -> ST_Envelope
--   12) lm_st_makeline      -> ST_MakeLine
--   13) lm_st_reverse       -> ST_Reverse
--   14) lm_st_flipcoordinates -> ST_FlipCoordinates
--   15) lm_st_within        -> ST_Within
--   16) lm_st_disjoint      -> ST_Disjoint
--   17) lm_st_area          -> ST_Area
--   18) lm_st_azimuth       -> ST_Azimuth
--   19) lm_st_ispolygonccw  -> ST_IsPolygonCCW
--   20) lm_st_ispolygoncw   -> ST_IsPolygonCW
--   21) lm_st_forcepolygonccw -> ST_ForcePolygonCCW
--   22) lm_st_forcepolygoncw  -> ST_ForcePolygonCW
--   23) lm_st_scale         -> ST_Scale
--   24) lm_st_pointinsidecircle -> ST_PointInsideCircle
--   25) lm_st_astext        -> ST_AsText
--   26) lm_st_asgeojson     -> ST_AsGeoJSON
--
-- ============================================================================


-- ============================================================
-- 1)  lm_st_x  —  PostGIS ST_X equivalent
--     Returns the X (longitude) of a point geometry.
-- ============================================================
CREATE OR REPLACE FUNCTION lm_st_x(p_geom geometry)
RETURNS double precision
LANGUAGE sql IMMUTABLE
AS $$
   SELECT (p_geom).lon[1];
$$;

-- Example:
--   SELECT lm_st_x(lm_make_point(-111.97, 40.52));
--   -- Returns: -111.97


-- ============================================================
-- 2)  lm_st_y  —  PostGIS ST_Y equivalent
--     Returns the Y (latitude) of a point geometry.
-- ============================================================
CREATE OR REPLACE FUNCTION lm_st_y(p_geom geometry)
RETURNS double precision
LANGUAGE sql IMMUTABLE
AS $$
   SELECT (p_geom).lat[1];
$$;

-- Example:
--   SELECT lm_st_y(lm_make_point(-111.97, 40.52));
--   -- Returns: 40.52


-- ============================================================
-- 3)  lm_st_npoints  —  PostGIS ST_NPoints equivalent
--     Returns the total number of vertices in the geometry.
-- ============================================================
CREATE OR REPLACE FUNCTION lm_st_npoints(p_geom geometry)
RETURNS integer
LANGUAGE sql IMMUTABLE
AS $$
   SELECT coalesce(array_length((p_geom).lon, 1), 0);
$$;

-- Example:
--   SELECT lm_st_npoints(lm_make_bbox(-112, 40, -111, 41));
--   -- Returns: 4


-- ============================================================
-- 4)  lm_geometry_type  —  PostGIS GeometryType equivalent
--     Returns 'POINT', 'LINESTRING', or 'POLYGON'.
-- ============================================================
CREATE OR REPLACE FUNCTION lm_geometry_type(p_geom geometry)
RETURNS text
LANGUAGE sql IMMUTABLE
AS $$
   SELECT CASE coalesce(array_length((p_geom).lon, 1), 0)
      WHEN 0 THEN 'EMPTY'
      WHEN 1 THEN 'POINT'
      WHEN 2 THEN 'LINESTRING'
      ELSE        'POLYGON'
   END;
$$;

-- Example:
--   SELECT lm_geometry_type(lm_make_point(-111.97, 40.52));
--   -- Returns: 'POINT'


-- ============================================================
-- 5)  lm_st_geometrytype  —  PostGIS ST_GeometryType equivalent
--     Returns 'ST_Point', 'ST_LineString', or 'ST_Polygon'.
-- ============================================================
CREATE OR REPLACE FUNCTION lm_st_geometrytype(p_geom geometry)
RETURNS text
LANGUAGE sql IMMUTABLE
AS $$
   SELECT CASE coalesce(array_length((p_geom).lon, 1), 0)
      WHEN 0 THEN 'ST_Empty'
      WHEN 1 THEN 'ST_Point'
      WHEN 2 THEN 'ST_LineString'
      ELSE        'ST_Polygon'
   END;
$$;


-- ============================================================
-- 6)  lm_st_startpoint  —  PostGIS ST_StartPoint equivalent
--     Returns the first vertex as a point geometry.
-- ============================================================
CREATE OR REPLACE FUNCTION lm_st_startpoint(p_geom geometry)
RETURNS geometry
LANGUAGE sql IMMUTABLE
AS $$
   SELECT lm_make_point((p_geom).lon[1], (p_geom).lat[1]);
$$;


-- ============================================================
-- 7)  lm_st_endpoint  —  PostGIS ST_EndPoint equivalent
--     Returns the last vertex as a point geometry.
-- ============================================================
CREATE OR REPLACE FUNCTION lm_st_endpoint(p_geom geometry)
RETURNS geometry
LANGUAGE sql IMMUTABLE
AS $$
   SELECT lm_make_point(
      (p_geom).lon[array_length((p_geom).lon, 1)],
      (p_geom).lat[array_length((p_geom).lat, 1)]
   );
$$;


-- ============================================================
-- 8)  lm_st_pointn  —  PostGIS ST_PointN equivalent
--     Returns the Nth vertex (1-based) as a point geometry.
-- ============================================================
CREATE OR REPLACE FUNCTION lm_st_pointn(p_geom geometry, p_n integer)
RETURNS geometry
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
   n integer := coalesce(array_length((p_geom).lon, 1), 0);
BEGIN
   IF p_n < 1 OR p_n > n THEN
      RETURN NULL;
   END IF;
   RETURN lm_make_point((p_geom).lon[p_n], (p_geom).lat[p_n]);
END;
$$;


-- ============================================================
-- 9)  lm_st_isclosed  —  PostGIS ST_IsClosed equivalent
--     Returns true if first vertex equals last vertex.
-- ============================================================
CREATE OR REPLACE FUNCTION lm_st_isclosed(p_geom geometry)
RETURNS boolean
LANGUAGE sql IMMUTABLE
AS $$
   SELECT (p_geom).lon[1] = (p_geom).lon[array_length((p_geom).lon, 1)]
      AND (p_geom).lat[1] = (p_geom).lat[array_length((p_geom).lat, 1)];
$$;


-- ============================================================
-- 10) lm_st_isempty  —  PostGIS ST_IsEmpty equivalent
--     Returns true if the geometry has no vertices.
-- ============================================================
CREATE OR REPLACE FUNCTION lm_st_isempty(p_geom geometry)
RETURNS boolean
LANGUAGE sql IMMUTABLE
AS $$
   SELECT coalesce(array_length((p_geom).lon, 1), 0) = 0;
$$;


-- ============================================================
-- 11) lm_st_envelope  —  PostGIS ST_Envelope equivalent
--     Returns the bounding box as a polygon geometry.
-- ============================================================
CREATE OR REPLACE FUNCTION lm_st_envelope(p_geom geometry)
RETURNS geometry
LANGUAGE sql IMMUTABLE
AS $$
   SELECT lm_make_bbox(
      lm_st_xmin(p_geom), lm_st_ymin(p_geom),
      lm_st_xmax(p_geom), lm_st_ymax(p_geom)
   );
$$;

-- Example:
--   SELECT lm_st_envelope(lm_make_polygon(
--       ARRAY[-112.0, -111.9, -111.85],
--       ARRAY[40.5,   40.55,  40.48]));


-- ============================================================
-- 12) lm_st_makeline  —  PostGIS ST_MakeLine equivalent
--     Creates a LineString from two point geometries.
-- ============================================================
CREATE OR REPLACE FUNCTION lm_st_makeline(p_a geometry, p_b geometry)
RETURNS geometry
LANGUAGE sql IMMUTABLE
AS $$
   SELECT ROW(
      (p_a).lon || (p_b).lon,
      (p_a).lat || (p_b).lat
   )::geometry;
$$;

-- Aggregate version: from an array of point geometries
CREATE OR REPLACE FUNCTION lm_st_makeline(p_points geometry[])
RETURNS geometry
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
   n integer := coalesce(array_length(p_points, 1), 0);
   out_lon double precision[] := ARRAY[]::double precision[];
   out_lat double precision[] := ARRAY[]::double precision[];
   i integer;
BEGIN
   IF n < 2 THEN
      RAISE EXCEPTION 'lm_st_makeline: need at least 2 points';
   END IF;
   FOR i IN 1..n LOOP
      out_lon := out_lon || (p_points[i]).lon;
      out_lat := out_lat || (p_points[i]).lat;
   END LOOP;
   RETURN ROW(out_lon, out_lat)::geometry;
END;
$$;


-- ============================================================
-- 13) lm_st_reverse  —  PostGIS ST_Reverse equivalent
--     Reverses the order of vertices.
-- ============================================================
CREATE OR REPLACE FUNCTION lm_st_reverse(p_geom geometry)
RETURNS geometry
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
   n integer := coalesce(array_length((p_geom).lon, 1), 0);
   out_lon double precision[] := ARRAY[]::double precision[];
   out_lat double precision[] := ARRAY[]::double precision[];
   i integer;
BEGIN
   FOR i IN REVERSE n..1 LOOP
      out_lon := out_lon || (p_geom).lon[i];
      out_lat := out_lat || (p_geom).lat[i];
   END LOOP;
   RETURN ROW(out_lon, out_lat)::geometry;
END;
$$;


-- ============================================================
-- 14) lm_st_flipcoordinates  —  PostGIS ST_FlipCoordinates
--     Swaps X (lon) and Y (lat) for all vertices.
-- ============================================================
CREATE OR REPLACE FUNCTION lm_st_flipcoordinates(p_geom geometry)
RETURNS geometry
LANGUAGE sql IMMUTABLE
AS $$
   SELECT ROW((p_geom).lat, (p_geom).lon)::geometry;
$$;


-- ============================================================
-- 15) lm_st_within  —  PostGIS ST_Within equivalent
--     Returns true if A is fully within B.
--     This is ST_Contains with arguments swapped.
-- ============================================================

-- Array version
CREATE OR REPLACE FUNCTION lm_st_within(
   p_lon_a double precision[], p_lat_a double precision[],
   p_lon_b double precision[], p_lat_b double precision[]
)
RETURNS boolean
LANGUAGE sql IMMUTABLE
AS $$
   SELECT lm_st_contains(p_lon_b, p_lat_b, p_lon_a, p_lat_a);
$$;

-- Geometry version
CREATE OR REPLACE FUNCTION lm_st_within(p_a geometry, p_b geometry)
RETURNS boolean
LANGUAGE sql IMMUTABLE
AS $$
   SELECT lm_st_contains(p_b, p_a);
$$;


-- ============================================================
-- 16) lm_st_disjoint  —  PostGIS ST_Disjoint equivalent
--     Returns true if geometries do not intersect at all.
-- ============================================================

-- Array version
CREATE OR REPLACE FUNCTION lm_st_disjoint(
   p_lon_a double precision[], p_lat_a double precision[],
   p_lon_b double precision[], p_lat_b double precision[]
)
RETURNS boolean
LANGUAGE sql IMMUTABLE
AS $$
   SELECT NOT lm_st_intersects(p_lon_a, p_lat_a, p_lon_b, p_lat_b);
$$;

-- Geometry version
CREATE OR REPLACE FUNCTION lm_st_disjoint(p_a geometry, p_b geometry)
RETURNS boolean
LANGUAGE sql IMMUTABLE
AS $$
   SELECT NOT lm_st_intersects(p_a, p_b);
$$;


-- ============================================================
-- 17) lm_st_area  —  PostGIS ST_Area equivalent
--     Computes the area of a polygon using the Shoelace formula.
--     Returns area in square degrees (planar).
-- ============================================================

-- Array version
CREATE OR REPLACE FUNCTION lm_st_area(
   p_lon double precision[], p_lat double precision[]
)
RETURNS double precision
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
   n integer := coalesce(array_length(p_lon, 1), 0);
   s double precision := 0;
   j integer;
   i integer;
BEGIN
   IF n < 3 THEN RETURN 0; END IF;
   j := n;
   FOR i IN 1..n LOOP
      s := s + (p_lon[j] + p_lon[i]) * (p_lat[j] - p_lat[i]);
      j := i;
   END LOOP;
   RETURN abs(s) / 2.0;
END;
$$;

-- Geometry version
CREATE OR REPLACE FUNCTION lm_st_area(p_geom geometry)
RETURNS double precision
LANGUAGE sql IMMUTABLE
AS $$
   SELECT lm_st_area((p_geom).lon, (p_geom).lat);
$$;

-- Example:
--   SELECT lm_st_area(lm_make_bbox(-112, 40, -111, 41));
--   -- Returns: 1.0  (1 square degree)


-- ============================================================
-- 18) lm_st_azimuth  —  PostGIS ST_Azimuth equivalent
--     Returns the angle in radians from point A to point B,
--     measured clockwise from north (positive Y).
--     Range: [0, 2*pi)
-- ============================================================
CREATE OR REPLACE FUNCTION lm_st_azimuth(p_a geometry, p_b geometry)
RETURNS double precision
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
   dx double precision := (p_b).lon[1] - (p_a).lon[1];
   dy double precision := (p_b).lat[1] - (p_a).lat[1];
   az double precision;
BEGIN
   IF dx = 0 AND dy = 0 THEN RETURN NULL; END IF;
   az := atan2(dx, dy);
   IF az < 0 THEN az := az + 2.0 * pi(); END IF;
   RETURN az;
END;
$$;

-- Example:
--   SELECT lm_st_azimuth(
--       lm_make_point(0, 0), lm_make_point(1, 1));
--   -- Returns: ~0.7854  (pi/4, i.e. 45 degrees = northeast)


-- ============================================================
-- Internal helper: signed area (positive = CCW, negative = CW)
-- ============================================================
CREATE OR REPLACE FUNCTION lm__signed_area(
   p_lon double precision[], p_lat double precision[]
)
RETURNS double precision
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
   n integer := coalesce(array_length(p_lon, 1), 0);
   s double precision := 0;
   j integer;
   i integer;
BEGIN
   IF n < 3 THEN RETURN 0; END IF;
   j := n;
   FOR i IN 1..n LOOP
      s := s + (p_lon[j] - p_lon[i]) * (p_lat[j] + p_lat[i]);
      j := i;
   END LOOP;
   RETURN s / 2.0;
END;
$$;


-- ============================================================
-- 19) lm_st_ispolygonccw  —  PostGIS ST_IsPolygonCCW equivalent
--     Returns true if the polygon vertices are counter-clockwise.
-- ============================================================
CREATE OR REPLACE FUNCTION lm_st_ispolygonccw(p_geom geometry)
RETURNS boolean
LANGUAGE sql IMMUTABLE
AS $$
   SELECT lm__signed_area((p_geom).lon, (p_geom).lat) > 0;
$$;


-- ============================================================
-- 20) lm_st_ispolygoncw  —  PostGIS ST_IsPolygonCW equivalent
--     Returns true if the polygon vertices are clockwise.
-- ============================================================
CREATE OR REPLACE FUNCTION lm_st_ispolygoncw(p_geom geometry)
RETURNS boolean
LANGUAGE sql IMMUTABLE
AS $$
   SELECT lm__signed_area((p_geom).lon, (p_geom).lat) < 0;
$$;


-- ============================================================
-- 21) lm_st_forcepolygonccw  —  PostGIS ST_ForcePolygonCCW
--     Returns the polygon with vertices in CCW order.
-- ============================================================
CREATE OR REPLACE FUNCTION lm_st_forcepolygonccw(p_geom geometry)
RETURNS geometry
LANGUAGE sql IMMUTABLE
AS $$
   SELECT CASE
      WHEN lm__signed_area((p_geom).lon, (p_geom).lat) < 0
      THEN lm_st_reverse(p_geom)
      ELSE p_geom
   END;
$$;


-- ============================================================
-- 22) lm_st_forcepolygoncw  —  PostGIS ST_ForcePolygonCW
--     Returns the polygon with vertices in CW order.
-- ============================================================
CREATE OR REPLACE FUNCTION lm_st_forcepolygoncw(p_geom geometry)
RETURNS geometry
LANGUAGE sql IMMUTABLE
AS $$
   SELECT CASE
      WHEN lm__signed_area((p_geom).lon, (p_geom).lat) > 0
      THEN lm_st_reverse(p_geom)
      ELSE p_geom
   END;
$$;


-- ============================================================
-- 23) lm_st_scale  —  PostGIS ST_Scale equivalent
--     Scales a geometry by sx (X factor) and sy (Y factor)
--     relative to the origin.
-- ============================================================

-- Array version
CREATE OR REPLACE FUNCTION lm_st_scale(
   p_lon double precision[], p_lat double precision[],
   p_sx  double precision,   p_sy  double precision
)
RETURNS geometry
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
   n integer := coalesce(array_length(p_lon, 1), 0);
   out_lon double precision[] := ARRAY[]::double precision[];
   out_lat double precision[] := ARRAY[]::double precision[];
   i integer;
BEGIN
   FOR i IN 1..n LOOP
      out_lon := out_lon || (p_lon[i] * p_sx);
      out_lat := out_lat || (p_lat[i] * p_sy);
   END LOOP;
   RETURN ROW(out_lon, out_lat)::geometry;
END;
$$;

-- Geometry version
CREATE OR REPLACE FUNCTION lm_st_scale(
   p_geom geometry,
   p_sx   double precision,
   p_sy   double precision
)
RETURNS geometry
LANGUAGE sql IMMUTABLE
AS $$
   SELECT lm_st_scale((p_geom).lon, (p_geom).lat, p_sx, p_sy);
$$;


-- ============================================================
-- 24) lm_st_pointinsidecircle  —  PostGIS ST_PointInsideCircle
--     Tests if a point is inside a circle defined by
--     center (cx, cy) and radius r (Euclidean / planar).
-- ============================================================
CREATE OR REPLACE FUNCTION lm_st_pointinsidecircle(
   p_point geometry,
   p_cx    double precision,
   p_cy    double precision,
   p_r     double precision
)
RETURNS boolean
LANGUAGE sql IMMUTABLE
AS $$
   SELECT ( ((p_point).lon[1] - p_cx) * ((p_point).lon[1] - p_cx)
          + ((p_point).lat[1] - p_cy) * ((p_point).lat[1] - p_cy) )
          <= (p_r * p_r);
$$;


-- ============================================================
-- 25) lm_st_astext  —  PostGIS ST_AsText equivalent
--     Returns the geometry as Well-Known Text (WKT).
-- ============================================================
CREATE OR REPLACE FUNCTION lm_st_astext(p_geom geometry)
RETURNS text
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
   n integer := coalesce(array_length((p_geom).lon, 1), 0);
   coords text := '';
   i integer;
BEGIN
   IF n = 0 THEN
      RETURN 'GEOMETRYCOLLECTION EMPTY';
   END IF;

   -- Build coordinate string
   FOR i IN 1..n LOOP
      IF i > 1 THEN coords := coords || ','; END IF;
      coords := coords || (p_geom).lon[i]::text || ' ' || (p_geom).lat[i]::text;
   END LOOP;

   IF n = 1 THEN
      RETURN 'POINT(' || coords || ')';
   ELSIF n = 2 THEN
      RETURN 'LINESTRING(' || coords || ')';
   ELSE
      -- Close the ring for WKT polygon output
      IF (p_geom).lon[1] <> (p_geom).lon[n]
         OR (p_geom).lat[1] <> (p_geom).lat[n] THEN
         coords := coords || ',' || (p_geom).lon[1]::text || ' ' || (p_geom).lat[1]::text;
      END IF;
      RETURN 'POLYGON((' || coords || '))';
   END IF;
END;
$$;

-- Example:
--   SELECT lm_st_astext(lm_make_point(-111.97, 40.52));
--   -- Returns: 'POINT(-111.97 40.52)'
--
--   SELECT lm_st_astext(lm_make_bbox(-112, 40, -111, 41));
--   -- Returns: 'POLYGON((-112 40,-111 40,-111 41,-112 41,-112 40))'


-- ============================================================
-- 26) lm_st_asgeojson  —  PostGIS ST_AsGeoJSON equivalent
--     Returns the geometry as a GeoJSON geometry object (text).
-- ============================================================
CREATE OR REPLACE FUNCTION lm_st_asgeojson(p_geom geometry)
RETURNS text
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
   n integer := coalesce(array_length((p_geom).lon, 1), 0);
   coords text := '';
   i integer;
BEGIN
   IF n = 0 THEN
      RETURN '{"type":"GeometryCollection","geometries":[]}';
   END IF;

   IF n = 1 THEN
      RETURN '{"type":"Point","coordinates":['
         || (p_geom).lon[1]::text || ',' || (p_geom).lat[1]::text || ']}';
   ELSIF n = 2 THEN
      FOR i IN 1..n LOOP
         IF i > 1 THEN coords := coords || ','; END IF;
         coords := coords || '[' || (p_geom).lon[i]::text || ',' || (p_geom).lat[i]::text || ']';
      END LOOP;
      RETURN '{"type":"LineString","coordinates":[' || coords || ']}';
   ELSE
      -- Polygon: ring must be closed in GeoJSON
      FOR i IN 1..n LOOP
         IF i > 1 THEN coords := coords || ','; END IF;
         coords := coords || '[' || (p_geom).lon[i]::text || ',' || (p_geom).lat[i]::text || ']';
      END LOOP;
      -- Close ring if not already closed
      IF (p_geom).lon[1] <> (p_geom).lon[n]
         OR (p_geom).lat[1] <> (p_geom).lat[n] THEN
         coords := coords || ',[' || (p_geom).lon[1]::text || ',' || (p_geom).lat[1]::text || ']';
      END IF;
      RETURN '{"type":"Polygon","coordinates":[[' || coords || ']]}';
   END IF;
END;
$$;

-- Example:
--   SELECT lm_st_asgeojson(lm_make_point(-111.97, 40.52));
--   -- Returns: '{"type":"Point","coordinates":[-111.97,40.52]}'
