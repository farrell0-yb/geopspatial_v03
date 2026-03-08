-- ============================================================================
--
-- Test queries for all functions.
--
-- Run these after executing files 10 through 30 in order.
-- Each query is independent.
--
-- Tests are organized to show BOTH calling styles:
--   - Array style  (the original lat/lon array signatures)
--   - Geometry style (the new geometry type signatures)
--
-- ============================================================================


-- =================================================================
-- SECTION A:  lm_st_contains
-- =================================================================

-- Test A1:  Array style -- large rectangle contains smaller one
--           Expected: true
--
SELECT lm_st_contains(
   ARRAY[-112.0, -111.8, -111.8, -112.0],
   ARRAY[40.4,   40.4,   40.6,   40.6],
   ARRAY[-111.95, -111.85, -111.85, -111.95],
   ARRAY[40.45,   40.45,   40.55,   40.55]
) AS "A1: contains (array) = true";

-- Test A2:  Geometry style -- same test
--           Expected: true
--
SELECT lm_st_contains(
   lm_make_polygon(
      ARRAY[-112.0, -111.8, -111.8, -112.0],
      ARRAY[40.4,   40.4,   40.6,   40.6]),
   lm_make_polygon(
      ARRAY[-111.95, -111.85, -111.85, -111.95],
      ARRAY[40.45,   40.45,   40.55,   40.55])
) AS "A2: contains (geometry) = true";

-- Test A3:  Reversed -- small does NOT contain large
--           Expected: false
--
SELECT lm_st_contains(
   lm_make_polygon(
      ARRAY[-111.95, -111.85, -111.85, -111.95],
      ARRAY[40.45,   40.45,   40.55,   40.55]),
   lm_make_polygon(
      ARRAY[-112.0, -111.8, -111.8, -112.0],
      ARRAY[40.4,   40.4,   40.6,   40.6])
) AS "A3: contains reversed = false";


-- =================================================================
-- SECTION B:  lm_st_xmin / lm_st_xmax / lm_st_ymin / lm_st_ymax
-- =================================================================

-- Test B1:  Array style
--           Expected: -112.0
--
SELECT lm_st_xmin(ARRAY[-112.0, -111.9, -111.9, -112.0])
   AS "B1: xmin (array) = -112.0";

-- Test B2:  Geometry style
--           Expected: -111.9
--
SELECT lm_st_xmax(
   lm_make_polygon(
      ARRAY[-112.0, -111.9, -111.9, -112.0],
      ARRAY[40.5,   40.5,   40.55,  40.55])
) AS "B2: xmax (geometry) = -111.9";

-- Test B3:  Array style
--           Expected: 40.5 and 40.55
--
SELECT lm_st_ymin(ARRAY[40.5, 40.5, 40.55, 40.55]) AS "B3a: ymin = 40.5",
       lm_st_ymax(ARRAY[40.5, 40.5, 40.55, 40.55]) AS "B3b: ymax = 40.55";

-- Test B4:  Geometry style
--           Expected: 40.5 and 40.55
--
SELECT lm_st_ymin(
   lm_make_polygon(
      ARRAY[-112.0, -111.9, -111.9, -112.0],
      ARRAY[40.5,   40.5,   40.55,  40.55])
) AS "B4a: ymin (geom) = 40.5",
lm_st_ymax(
   lm_make_polygon(
      ARRAY[-112.0, -111.9, -111.9, -112.0],
      ARRAY[40.5,   40.5,   40.55,  40.55])
) AS "B4b: ymax (geom) = 40.55";


-- =================================================================
-- SECTION C:  lm_st_translate
-- =================================================================

-- Test C1:  Array style -- shift 0.01 east, 0.02 south
--           Expected: out_lon={-111.99,-111.89,-111.89,-111.99}
--                     out_lat={40.48,40.48,40.53,40.53}
--
SELECT * FROM lm_st_translate(
   ARRAY[-112.0, -111.9, -111.9, -112.0],
   ARRAY[40.5,   40.5,   40.55,  40.55],
   0.01, -0.02
);

-- Test C2:  Geometry style -- same shift, returns a geometry
--
SELECT lm_st_translate(
   lm_make_polygon(
      ARRAY[-112.0, -111.9, -111.9, -112.0],
      ARRAY[40.5,   40.5,   40.55,  40.55]),
   0.01, -0.02
) AS "C2: translated geometry";


-- =================================================================
-- SECTION D:  lm_st_intersects
-- =================================================================

-- Test D1:  Array style -- overlapping rectangles
--           Expected: true
--
SELECT lm_st_intersects(
   ARRAY[-112.0, -111.9, -111.9, -112.0],
   ARRAY[40.5,   40.5,   40.55,  40.55],
   ARRAY[-111.95, -111.85, -111.85, -111.95],
   ARRAY[40.52,   40.52,   40.57,   40.57]
) AS "D1: intersects (array) = true";

-- Test D2:  Geometry style -- same test
--           Expected: true
--
SELECT lm_st_intersects(
   lm_make_polygon(
      ARRAY[-112.0, -111.9, -111.9, -112.0],
      ARRAY[40.5,   40.5,   40.55,  40.55]),
   lm_make_polygon(
      ARRAY[-111.95, -111.85, -111.85, -111.95],
      ARRAY[40.52,   40.52,   40.57,   40.57])
) AS "D2: intersects (geometry) = true";

-- Test D3:  Non-overlapping rectangles
--           Expected: false
--
SELECT lm_st_intersects(
   lm_make_polygon(
      ARRAY[-112.0, -111.9, -111.9, -112.0],
      ARRAY[40.5,   40.5,   40.55,  40.55]),
   lm_make_polygon(
      ARRAY[-111.0, -110.9, -110.9, -111.0],
      ARRAY[41.0,   41.0,   41.05,  41.05])
) AS "D3: intersects far apart = false";


-- =================================================================
-- SECTION E:  point_in_polygon
-- =================================================================

-- Test E1:  lat/lon style
--           Expected: true
--
SELECT point_in_polygon(
   -111.97, 40.52,
   ARRAY[-112.0, -111.9, -111.9, -112.0],
   ARRAY[40.5, 40.5, 40.55, 40.55]
) AS "E1: point_in_polygon (lat/lon) = true";

-- Test E2:  Geometry style
--           Expected: true
--
SELECT point_in_polygon(
   lm_make_point(-111.97, 40.52),
   lm_make_polygon(
      ARRAY[-112.0, -111.9, -111.9, -112.0],
      ARRAY[40.5, 40.5, 40.55, 40.55])
) AS "E2: point_in_polygon (geometry) = true";


-- =================================================================
-- SECTION F:  geohash_decode_bbox (both forms)
-- =================================================================

-- Test F1:  TABLE-returning version
--           Expected: lat_min, lat_max, lon_min, lon_max
--
SELECT * FROM geohash_decode_bbox('9x0qs0');

-- Test F2:  Geometry-returning version
--           Expected: a geometry rectangle
--
SELECT geohash_decode_bbox_geom('9x0qs0') AS "F2: bbox as geometry";


-- =================================================================
-- SECTION G:  geohash_cell_center (both forms)
-- =================================================================

-- Test G1:  TABLE-returning version
--           Expected: lat, lon
--
SELECT * FROM geohash_cell_center('9x0qs0');

-- Test G2:  Geometry-returning version
--           Expected: a geometry point
--
SELECT geohash_cell_center_geom('9x0qs0') AS "G2: center as geometry";


-- =================================================================
-- SECTION H:  Using geohash bounding boxes with spatial functions
-- =================================================================

-- Test H1:  A precision-6 cell contains its child precision-8 cell
--           Using TABLE style with manual array construction
--           Expected: true
--
WITH
   a AS (SELECT * FROM geohash_decode_bbox('9x0qs0')),
   b AS (SELECT * FROM geohash_decode_bbox('9x0qs0fd'))
SELECT lm_st_contains(
   ARRAY[a.lon_min, a.lon_max, a.lon_max, a.lon_min],
   ARRAY[a.lat_min, a.lat_min, a.lat_max, a.lat_max],
   ARRAY[b.lon_min, b.lon_max, b.lon_max, b.lon_min],
   ARRAY[b.lat_min, b.lat_min, b.lat_max, b.lat_max]
) AS "H1: parent contains child (array) = true"
FROM a, b;

-- Test H2:  Same test using geometry style -- much cleaner
--           Expected: true
--
SELECT lm_st_contains(
   geohash_decode_bbox_geom('9x0qs0'),
   geohash_decode_bbox_geom('9x0qs0fd')
) AS "H2: parent contains child (geometry) = true";


-- =================================================================
-- SECTION I:  Table geometry column
--             (only works after 15_LoadData.sql has been run)
-- =================================================================

-- Test I1:  Query the table using the geometry column
--
-- SELECT md_pk, md_name,
--        (geom).lon[1] AS lng,
--        (geom).lat[1] AS lat
-- FROM my_mapdata
-- WHERE geom IS NOT NULL
-- LIMIT 5;
