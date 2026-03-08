

-- ============================================================================
--
-- Purpose  : Create the my_mapdata table with a geometry column.
--
-- Requires : 10_CreateGeometryType.sql  (defines the geometry type)
--
-- The table stores point-of-interest records.  Each row has:
--   - Standard address/category fields (loaded from the pipe file)
--   - A geohash10 TEXT column used for spatial indexing
--   - A geo_hash8 TEXT column (first 8 chars of geohash10) for finer lookups
--   - A geom GEOMETRY column holding the point as lm_make_point(lng, lat)
--
-- ============================================================================

DROP TABLE IF EXISTS my_mapdata;

CREATE TABLE my_mapdata
   (
   md_pk                 BIGINT NOT NULL,
   md_lat                TEXT,
   md_lng                TEXT,
   geo_hash10            TEXT,
   geom                  geometry,
   geo_hash8             TEXT,
   md_name               TEXT,
   md_address            TEXT,
   md_city               TEXT,
   md_province           TEXT,
   md_country            TEXT,
   md_postcode           TEXT,
   md_phone              TEXT,
   md_category           TEXT,
   md_subcategory        TEXT,
   md_mysource           TEXT,
   md_tags               TEXT,
   md_type               TEXT,
   PRIMARY KEY ((md_pk) HASH)
   );

-- Full geohash10 + name index
--
CREATE INDEX ix_my_mapdata2
   ON my_mapdata (geo_hash10, md_name);

-- Best index for the speed = 80 use case,
-- because of how we build that data set.
--
CREATE INDEX IF NOT EXISTS ix_mapdata3
   ON my_mapdata (left(geo_hash10, 5), md_name);

-- Best index for the walking use case
--
CREATE INDEX IF NOT EXISTS ix_mapdata4
   ON my_mapdata (left(geo_hash10, 6), md_name);

-- Index on geo_hash8 for equality lookups
--
CREATE INDEX IF NOT EXISTS ix_mapdata_geo_hash8
   ON my_mapdata (geo_hash8);



