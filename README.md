# PostGIS Geometry Functions Reference — YugabyteDB Pure-SQL Replacement

## Overview

This project provides a complete pure PL/pgSQL implementation of PostGIS geometry functions for YugabyteDB YSQL. No C extensions are required.

**Scope:**
- Geometry type only (no geography, no raster)
- No WKB/bytea support
- GeoJSON input/output supported
- All functions are pure SQL + PL/pgSQL
- Target database: YugabyteDB YSQL (also compatible with PostgreSQL)

---

## Geometry Type

Defined in `10_CreateGeometryType.sql`:

```sql
CREATE TYPE geometry AS (
   lon   double precision[],
   lat   double precision[]
);
```

- **Point:** Single-element arrays — `lm_make_point(lon, lat)`
- **LineString:** Two-element arrays — `lm_st_makeline(point_a, point_b)`
- **Polygon:** 3+ vertex arrays — `lm_make_polygon(lon[], lat[])`
- **Bounding Box:** 4-vertex rectangle — `lm_make_bbox(xmin, ymin, xmax, ymax)`

---

## File Index

| File | Contents |
|------|----------|
| `10_CreateGeometryType.sql` | geometry type + 3 constructors |
| `11_CreateSchema.sql` | Table schema + indexes |
| `15_LoadData.sql` | Data loading |
| `19_mapData.pipe` | 344,688 POI records (Colorado) |
| `20_GeohashFunctions.sql` | 14 geohash functions |
| `25_GeometryFunctions.sql` | 7 core spatial functions (original) |
| `26_Tier1_GeometryFunctions.sql` | 26 Tier 1 functions (quick wins) |
| `27_Tier2_GeometryFunctions.sql` | 28 Tier 2 functions (core spatial) |
| `28_Tier3_GeometryFunctions.sql` | 12 Tier 3 functions (advanced algorithms) |
| `30_GeohashPolygonFunctions.sql` | Polygon coverage functions |
| `35_TestQueries.sql` | Test suite |

---

## Complete Function Reference

### Constructors (file: 10_CreateGeometryType.sql)

| Function | PostGIS Equivalent | Description |
|----------|-------------------|-------------|
| `lm_make_point(lon, lat)` | ST_MakePoint | Creates a point geometry |
| `lm_make_polygon(lon[], lat[])` | ST_MakePolygon | Creates a polygon from vertex arrays |
| `lm_make_bbox(xmin, ymin, xmax, ymax)` | ST_MakeEnvelope | Creates a bounding-box rectangle |

### Original Core Functions (file: 25_GeometryFunctions.sql)

| Function | PostGIS Equivalent | Description |
|----------|-------------------|-------------|
| `lm_st_xmin(geom)` | ST_XMin | Minimum longitude |
| `lm_st_xmax(geom)` | ST_XMax | Maximum longitude |
| `lm_st_ymin(geom)` | ST_YMin | Minimum latitude |
| `lm_st_ymax(geom)` | ST_YMax | Maximum latitude |
| `lm_st_translate(geom, dx, dy)` | ST_Translate | Shift geometry by offset |
| `lm_st_intersects(a, b)` | ST_Intersects | Test if geometries share any space |
| `lm_st_contains(a, b)` | ST_Contains | Test if A fully contains B |

### Tier 1: Quick Wins (file: 26_Tier1_GeometryFunctions.sql)

| # | Function | PostGIS Equivalent | Description |
|---|----------|-------------------|-------------|
| 1 | `lm_st_x(geom)` | ST_X | X coordinate of a point |
| 2 | `lm_st_y(geom)` | ST_Y | Y coordinate of a point |
| 3 | `lm_st_npoints(geom)` | ST_NPoints | Number of vertices |
| 4 | `lm_geometry_type(geom)` | GeometryType | Returns 'POINT', 'LINESTRING', or 'POLYGON' |
| 5 | `lm_st_geometrytype(geom)` | ST_GeometryType | Returns 'ST_Point', 'ST_LineString', or 'ST_Polygon' |
| 6 | `lm_st_startpoint(geom)` | ST_StartPoint | First vertex as point |
| 7 | `lm_st_endpoint(geom)` | ST_EndPoint | Last vertex as point |
| 8 | `lm_st_pointn(geom, n)` | ST_PointN | Nth vertex as point (1-based) |
| 9 | `lm_st_isclosed(geom)` | ST_IsClosed | True if first = last vertex |
| 10 | `lm_st_isempty(geom)` | ST_IsEmpty | True if no vertices |
| 11 | `lm_st_envelope(geom)` | ST_Envelope | Bounding box as polygon |
| 12 | `lm_st_makeline(a, b)` | ST_MakeLine | Create line from two points |
| 12b | `lm_st_makeline(points[])` | ST_MakeLine | Create line from array of points |
| 13 | `lm_st_reverse(geom)` | ST_Reverse | Reverse vertex order |
| 14 | `lm_st_flipcoordinates(geom)` | ST_FlipCoordinates | Swap X and Y |
| 15 | `lm_st_within(a, b)` | ST_Within | True if A is within B |
| 16 | `lm_st_disjoint(a, b)` | ST_Disjoint | True if no intersection |
| 17 | `lm_st_area(geom)` | ST_Area | Polygon area (shoelace formula, square degrees) |
| 18 | `lm_st_azimuth(a, b)` | ST_Azimuth | Bearing in radians, CW from north |
| 19 | `lm_st_ispolygonccw(geom)` | ST_IsPolygonCCW | True if vertices are counter-clockwise |
| 20 | `lm_st_ispolygoncw(geom)` | ST_IsPolygonCW | True if vertices are clockwise |
| 21 | `lm_st_forcepolygonccw(geom)` | ST_ForcePolygonCCW | Force CCW vertex order |
| 22 | `lm_st_forcepolygoncw(geom)` | ST_ForcePolygonCW | Force CW vertex order |
| 23 | `lm_st_scale(geom, sx, sy)` | ST_Scale | Scale geometry by factors |
| 24 | `lm_st_pointinsidecircle(pt, cx, cy, r)` | ST_PointInsideCircle | Point-in-circle test |
| 25 | `lm_st_astext(geom)` | ST_AsText | WKT output |
| 26 | `lm_st_asgeojson(geom)` | ST_AsGeoJSON | GeoJSON output |

### Tier 2: Core Spatial Functions (file: 27_Tier2_GeometryFunctions.sql)

| # | Function | PostGIS Equivalent | Description |
|---|----------|-------------------|-------------|
| 1 | `lm_st_distance(a, b)` | ST_Distance | Minimum planar distance |
| 2 | `lm_st_length(geom)` | ST_Length | Length of linestring |
| 3 | `lm_st_perimeter(geom)` | ST_Perimeter | Perimeter of polygon |
| 4 | `lm_st_centroid(geom)` | ST_Centroid | Geometric center of mass |
| 5 | `lm_st_distancesphere(a, b)` | ST_DistanceSphere | Great-circle distance (meters, Haversine) |
| 6 | `lm_st_dwithin(a, b, dist)` | ST_DWithin | Within-distance predicate |
| 7 | `lm_st_simplify(geom, tolerance)` | ST_Simplify | Douglas-Peucker simplification |
| 8 | `lm_st_lineinterpolatepoint(geom, frac)` | ST_LineInterpolatePoint | Point at fraction along line |
| 9 | `lm_st_linelocatepoint(line, point)` | ST_LineLocatePoint | Fraction of nearest point on line |
| 10 | `lm_st_linesubstring(geom, start, end)` | ST_LineSubstring | Sub-line between fractions |
| 11 | `lm_st_geomfromtext(wkt)` | ST_GeomFromText | Parse WKT string |
| 12 | `lm_st_geomfromgeojson(json)` | ST_GeomFromGeoJSON | Parse GeoJSON string |
| 13 | `lm_st_rotate(geom, angle, cx, cy)` | ST_Rotate | 2D rotation |
| 14 | `lm_st_affine(geom, a,b,d,e,xoff,yoff)` | ST_Affine | General 2D affine transform |
| 15 | `lm_st_dumppoints(geom)` | ST_DumpPoints | Returns set of (path, point) |
| 16 | `lm_st_dumpsegments(geom)` | ST_DumpSegments | Returns set of (path, segment) |
| 17 | `lm_st_snaptogrid(geom, size)` | ST_SnapToGrid | Round coordinates to grid |
| 18 | `lm_st_removerepeatedpoints(geom, tol)` | ST_RemoveRepeatedPoints | Remove duplicate adjacent vertices |
| 19 | `lm_st_segmentize(geom, max_len)` | ST_Segmentize | Densify long segments |
| 20 | `lm_st_clipbybox2d(geom, xmin,ymin,xmax,ymax)` | ST_ClipByBox2D | Sutherland-Hodgman clip to box |
| 21 | `lm_st_generatepoints(geom, n)` | ST_GeneratePoints | N random points inside polygon |
| 22 | `lm_st_chaikinsmoothing(geom, iters)` | ST_ChaikinSmoothing | Corner-cutting smoothing |
| 23 | `lm_st_expand(geom, amount)` | ST_Expand | Expand bounding box |
| 24 | `lm_st_summary(geom)` | ST_Summary | Text description of geometry |
| 25 | `lm_st_addpoint(geom, point, pos)` | ST_AddPoint | Add vertex at position |
| 26 | `lm_st_removepoint(geom, index)` | ST_RemovePoint | Remove vertex at index |
| 27 | `lm_st_setpoint(geom, index, point)` | ST_SetPoint | Replace vertex at index |
| 28 | `lm_st_project(point, dist_m, azimuth)` | ST_Project | Project point by distance/bearing |

### Tier 3: Advanced Algorithms (file: 28_Tier3_GeometryFunctions.sql)

| # | Function | PostGIS Equivalent | Description |
|---|----------|-------------------|-------------|
| 1 | `lm_st_convexhull(geom)` | ST_ConvexHull | Convex hull (Graham scan) |
| 2 | `lm_st_intersection(a, b)` | ST_Intersection | Polygon intersection (Sutherland-Hodgman, convex) |
| 3 | `lm_st_union(a, b)` | ST_Union | Union via convex hull of combined vertices |
| 4 | `lm_st_difference(a, b)` | ST_Difference | Part of A not in B |
| 5 | `lm_st_symdifference(a, b)` | ST_SymDifference | Parts in A or B but not both |
| 6 | `lm_st_buffer(geom, dist, segs)` | ST_Buffer | Approximate buffer (circle for points, offset for polygons) |
| 7 | `lm_st_isvalid(geom)` | ST_IsValid | OGC validity check |
| 8 | `lm_st_touches(a, b)` | ST_Touches | Boundary contact, no interior overlap |
| 9 | `lm_st_crosses(a, b)` | ST_Crosses | Partial interior intersection |
| 10 | `lm_st_overlaps(a, b)` | ST_Overlaps | Same-dim partial overlap |
| 11 | `lm_st_equals(a, b)` | ST_Equals | Topological equality |
| 12 | `lm_st_simplify_vw(geom, threshold)` | ST_SimplifyVW | Visvalingam-Whyatt simplification |

### Geohash Functions (file: 20_GeohashFunctions.sql)

| Function | Description |
|----------|-------------|
| `geohash_encode(lat, lon, precision)` | Encode lat/lon to geohash string |
| `geohash_adjacent(hash, dir)` | Neighboring geohash cell |
| `geohash_neighbors(hash)` | All 8 surrounding cells as JSONB |
| `geohash_precision_for_miles(miles)` | Appropriate precision for radius |
| `geohash_cell_height_miles(precision)` | Cell height in miles |
| `geohash_move(hash, dir, steps)` | Move N steps in a direction |
| `geohash_in_list_within_miles(hash, miles)` | IN-clause list of cells in radius |
| `geohash_in_list_within_miles_dir(hash, miles, dirs[])` | Directional IN-clause |
| `geohash_decode_bbox(hash)` | Decode to bounding box coordinates |
| `geohash_decode_bbox_geom(hash)` | Decode to bbox as geometry |
| `geohash_cell_center(hash)` | Center point coordinates |
| `geohash_cell_center_geom(hash)` | Center point as geometry |
| `point_in_polygon(lon, lat, lon[], lat[])` | Ray-casting point-in-polygon test |
| `point_in_polygon(point, polygon)` | Geometry overload |

### Polygon Coverage (file: 30_GeohashPolygonFunctions.sql)

| Function | Description |
|----------|-------------|
| `geohash8_fully_within_polygon(hashes[])` | Geohash-8 cells fully inside polygon |
| `geohash8_fully_within_polygon(p1..p5)` | Convenience overload with individual args |

---

## Total Function Count

| Category | Count |
|----------|-------|
| Constructors | 3 |
| Original core (25_) | 7 |
| Tier 1 quick wins (26_) | 26 |
| Tier 2 core spatial (27_) | 28 |
| Tier 3 advanced (28_) | 12 |
| Geohash functions (20_) | 14 |
| Polygon coverage (30_) | 2 |
| **Total** | **92** |

---

## Calling Conventions

Every spatial function supports dual calling styles:

**Array style:**
```sql
SELECT lm_st_contains(
    ARRAY[-112.0, -111.8, -111.8, -112.0],
    ARRAY[40.4,   40.4,   40.6,   40.6],
    ARRAY[-111.95, -111.85, -111.85, -111.95],
    ARRAY[40.45,   40.45,   40.55,   40.55]);
```

**Geometry style:**
```sql
SELECT lm_st_contains(
    lm_make_polygon(
        ARRAY[-112.0, -111.8, -111.8, -112.0],
        ARRAY[40.4,   40.4,   40.6,   40.6]),
    lm_make_polygon(
        ARRAY[-111.95, -111.85, -111.85, -111.95],
        ARRAY[40.45,   40.45,   40.55,   40.55]));
```

**Geohash + Geometry:**
```sql
SELECT lm_st_contains(
    geohash_decode_bbox_geom('9x0qs0'),
    geohash_decode_bbox_geom('9x0qs0fd'));
```

---

## Installation Order

```sql
\i 10_CreateGeometryType.sql
\i 11_CreateSchema.sql
\i 20_GeohashFunctions.sql
\i 25_GeometryFunctions.sql
\i 26_Tier1_GeometryFunctions.sql
\i 27_Tier2_GeometryFunctions.sql
\i 28_Tier3_GeometryFunctions.sql
\i 30_GeohashPolygonFunctions.sql
-- Optional:
\i 15_LoadData.sql
\i 35_TestQueries.sql
```

---

## Not Implemented (Requires GEOS C Library)

The following PostGIS functions are not feasible in pure PL/pgSQL and are intentionally excluded:

- ST_MakeValid (GEOS noding engine)
- ST_Node (GEOS noding)
- ST_BuildArea (GEOS planar graph)
- ST_Polygonize (GEOS planar graph)
- ST_LargestEmptyCircle (GEOS Voronoi)
- ST_LineToCurve (arc fitting)
- ST_ForceCurve (arc fitting)
- ST_Letters (font rendering)
- ST_AsMVT / ST_AsMVTGeom (binary tile encoding)
- ST_AsFlatGeobuf (binary format)
- ST_EstimatedExtent (planner statistics)

---

## Implementation Notes

### Tier 3 Caveats

- **ST_Intersection**: Uses Sutherland-Hodgman, which is exact for convex polygon pairs. For non-convex polygons, decompose into convex parts first or accept approximate results.
- **ST_Union**: Returns the convex hull of combined vertices. Exact for convex inputs; outer bound for non-convex.
- **ST_Difference**: Uses vertex walk with intersection point insertion. Exact for convex polygon pairs.
- **ST_Buffer**: Approximates offset curves. For points, generates a regular polygon (circle approximation). For polygons, offsets vertices along bisector normals. Set `p_segments` higher for smoother circles (default 8 = 32-sided polygon).
- **ST_IsValid**: Checks finite coordinates, non-zero area, and self-intersection of non-adjacent edges. Does not check ring orientation or hole containment (holes not supported in this geometry type).

### Performance

All functions are marked `IMMUTABLE` for query planner optimization. Functions that accept both array-style and geometry-style arguments have the geometry version delegate to the array version to avoid code duplication.

### Coordinate System

All functions assume SRID 4326 (WGS 84) with:
- X = longitude (degrees)
- Y = latitude (degrees)

`ST_DistanceSphere` and `ST_Project` use the Haversine formula with Earth radius = 6,371,000 meters.
