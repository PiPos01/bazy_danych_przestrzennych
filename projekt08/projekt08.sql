--set GTIFF_SRS_SOURCE=EPSG
--raster2pgsql.exe -s 27700 -N -32767 -t 100x100 -I -C -M -d "C:\Users\Piotr\Desktop\BDP\cwiczenia8\ras250_gb\data\SD.tif" uk_250k | psql -d cwiczenia_8_bdp -h localhost -U postgres -p 5432
ALTER TABLE uk_250k DROP CONSTRAINT enforce_max_extent_rast;
--raster2pgsql.exe -s 2770 -N -32767 -t 100x100 -I -C -M -a "C:\Users\Piotr\Desktop\BDP\cwiczenia8\ras250_gb\data\NY.tif" uk_250k | psql -d cwiczenia_8_bdp -h localhost -U postgres -p 5432
SELECT ST_SRID(rast) FROM uk_250k LIMIT 1
--ogr2ogr -f "PostgreSQL" "PG:dbname='cwiczenia_8_bdp' host='localhost' user='postgres' password='postgres' port='5432'" "C:\Users\Piotr\Desktop\BDP\cwiczenia8\OS_Open_Zoomstack.gpkg" -nln national_parks_27700 -s_srs EPSG:27700 -t_srs EPSG:27700 -lco GEOMETRY_NAME=geom "national_parks"
--SELECT ST_SRID(geom) FROM national_parks LIMIT 1
--SELECT ST_SRID(rast) FROM sentinel LIMIT 1


--SET GTIFF_SRS_SOURCE=EPSG
--raster2pgsql -s 27700 -I -C -M "C:\Users\Piotr\Desktop\BDP\cwiczenia8\ras250_gb\data\*.tif" uk_250k1 > "C:\Users\Piotr\Desktop\BDP\cwiczenia8\cw8.sql"
-- "C:\Program Files\PostgreSQL\17\bin\psql.exe" -U postgres -d cwiczenia_8_bdp -f "C:\Users\Piotr\Desktop\BDP\cwiczenia8\cw8.sql"
-- laczenie w mozaike
-- DROP TABLE uk_union
CREATE TABLE uk_union1 AS
SELECT ST_UNION(rast) AS rast
FROM uk_250k1


-- eksport
DROP TABLE raster1
CREATE TABLE raster1 AS
SELECT lo_from_bytea(0, ST_AsGDALRaster((rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
		'PREDICTOR=2', 'PZLEVEL=9'])
		) AS loid
FROM uk_union1;

SELECT lo_export(loid, 'C:\Program Files\PostgreSQL\17\data\raster1.tiff')
FROM raster1;

-- przycinka do granic parkow
-- DROP TABLE uk_lake_district
CREATE TABLE uk_lake_district_clipped AS
SELECT ST_Clip(a.rast, b.geom, true) AS rast
FROM uk_union AS a, national_parks AS b
WHERE b.id = 1 AND ST_Intersects(a.rast, b.geom)

-- eksport
CREATE TABLE raster2 AS
SELECT lo_from_bytea(0, ST_AsGDALRaster((clip), 'GTiff', ARRAY['COMPRESS=DEFLATE',
		'PREDICTOR=2', 'PZLEVEL=9'])
		) AS loid
FROM uk_lake_district;

SELECT lo_export(loid, 'C:\Program Files\PostgreSQL\17\data\raster2.tiff')
FROM raster2;

-- C:\Users\Piotr\Desktop\BDP\cwiczenia8\sentinel>gdal_translate -of GTiff B04_10m.jp2 B4_10m.tif
-- raster2pgsql.exe -s 27700 -N -32767 -t 128x128 -I -C -M -d "C:\Users\Piotr\Desktop\BDP\cwiczenia8\sentinel\B4_10m_27700.tif" sentinel | psql -d cwiczenia_8_bdp -h localhost -U postgres -p 5432
--ALTER TABLE sentinel DROP CONSTRAINT enforce_same_alignment_rast;
-- raster2pgsql.exe -s 27700 -N -32767 -t 128x128 -I -C -M -a "C:\Users\Piotr\Desktop\BDP\cwiczenia8\sentinel2\B4_2_10m_27700.tif" sentinel | psql -d cwiczenia_8_bdp -h localhost -U postgres -p 5432
--select pg_terminate_backend(20428)

-- gdalinfo "C:\Users\Piotr\Desktop\BDP\cwiczenia8\sentinel\TCI_10m.tif"

-- gdalwarp -t_srs EPSG:27700 -s_srs EPSG:4326 "C:\Users\Piotr\Desktop\BDP\cwiczenia8\sentinel\B4_10m.tif" "C:\Users\Piotr\Desktop\BDP\cwiczenia8\sentinel\B4_10m_27700.tif" -multi -co "COMPRESS=LZW"  

-- gdalwarp -t_srs EPSG:27700 "C:\Users\Piotr\Desktop\BDP\cwiczenia8\sentinel\B4_10m.tif" "C:\Users\Piotr\Desktop\BDP\cwiczenia8\sentinel\B4_10m_27700.tif" -srcnodata 0 -dstnodata 0 -multi -co "COMPRESS=LZW"

--C:\Users\Piotr>gdalwarp -t_srs EPSG:27700 "C:\Users\Piotr\Desktop\BDP\cwiczenia8\sentinel2\B4_2_10m.tif" "C:\Users\Piotr\Desktop\BDP\cwiczenia8\sentinel2\B4_2_10m_27700.tif" -srcnodata 0 -dstnodata 0 -multi -co "COMPRESS=LZW"

CREATE TABLE clipped_lake_ndwi AS
WITH greenClipped AS (
		SELECT a.rid, ST_Clip(a.rast, b.geom, true) AS rast_green
		FROM sentinel3 AS a, national_parks AS b
		WHERE b.id = 1 AND ST_Intersects(a.rast, b.geom)
),
nirClipped AS (
		SELECT c.rid, ST_Clip(c.rast, b.geom, true) AS rast_nir
		FROM sentinel8 AS c, national_parks AS b
		WHERE b.id = 1 AND ST_Intersects(c.rast, b.geom)
)
SELECT g.rid, ST_MapAlgebra(
			g.rast_green, 
			n.rast_nir,
			'([rast1.val] - [rast2.val]) / ([rast1.val] + [rast2.val])', 
			'32BF'
			) AS ndwi_rast
FROM greenClipped g JOIN nirClipped AS n on g.rid=n.rid;

-- DROP TABLE raster3
CREATE TABLE raster3 AS
SELECT lo_from_bytea(0, ST_AsGDALRaster(ST_UNION(ndwi_rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
		'PREDICTOR=2', 'PZLEVEL=9'])
		) AS loid
FROM clipped_lake_ndwi;

SELECT lo_export(loid, 'C:\Program Files\PostgreSQL\17\data\raster3.tiff')
FROM raster3;



-- union sentinel b3
DROP TABLE unioned_b3
CREATE TABLE unioned_b3 AS
SELECT rid, rast FROM sentinel3
UNION ALL
SELECT rid, rast FROM sentinel2_b3;

-- clip do parku
DROP TABLE clipped_unioned_b3_1
CREATE TABLE clipped_unioned_b3_1 AS
SELECT a.rid, ST_Clip(a.rast, b.geom,true) AS rast
FROM unioned_b3 AS a, national_parks AS b
WHERE b.id =1 AND ST_Intersects(a.rast,b.geom)

-- union sentinel b8
DROP TABLE unioned_b8
CREATE TABLE unioned_b8 AS
SELECT rid, rast FROM sentinel8
UNION ALL
SELECT rid, rast FROM sentinel2_b8;


-- clip do parku
DROP TABLE clipped_unioned_b8_1
CREATE TABLE clipped_unioned_b8_1 AS
SELECT a.rid, ST_Clip(a.rast, b.geom, true) AS rast
FROM unioned_b8 AS a, national_parks AS b
WHERE b.id =1 AND ST_Intersects(a.rast, b.geom)


SELECT rid, ST_Width(rast), ST_Height(rast), ST_PixelWidth(rast), ST_PixelHeight(rast), ST_SRID(rast)
FROM clipped_unioned_b3_1;

SELECT rid, ST_Width(rast), ST_Height(rast), ST_PixelWidth(rast), ST_PixelHeight(rast), ST_SRID(rast)
FROM clipped_unioned_b8_1;



-- ndwi
CREATE TABLE NEW_ndwi_lake AS
SELECT ST_MapAlgebra(
				a.rast,
				b.rast,
				'([rast1.val] - [rast2.val]) / ([rast1.val] + [rast2.val])', 
				'32BF'
			) AS ndwi_rast_new
FROM clipped_unioned_b3_1 AS a
JOIN clipped_unioned_b8_1  AS b
ON a.rid = b.rid;


--eksport
CREATE TABLE raster4 AS
SELECT lo_from_bytea(0, ST_AsGDALRaster(ST_UNION(ndwi_rast_new), 'GTiff', ARRAY['COMPRESS=DEFLATE',
		'PREDICTOR=2', 'PZLEVEL=9'])
		) AS loid
FROM NEW_ndwi_lake;

SELECT lo_export(loid, 'C:\Program Files\PostgreSQL\17\data\raster4.tiff')
FROM raster4;


