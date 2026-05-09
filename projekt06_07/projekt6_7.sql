-- zmiana nazwy schema_name
--ALTER SCHEMA schema_name RENAME TO poswietny

--CREATE EXTENSION postgis_raster

-- przyklad 1
CREATE TABLE poswietny.intersects AS 
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto'
-- ilike porównuje łańcuchy tekstowe ignorując wielkości liter

ALTER TABLE poswietny.intersects
ADD COLUMN rid SERIAL PRIMARY KEY;

CREATE INDEX idx_intersects_rast_gist ON poswietny.intersects
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('poswietny'::name, 'intersects'::name, 'rast'::name)

-- przyklad 2
CREATE TABLE poswietny.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO'

-- przyklad 3
CREATE TABLE poswietny.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' AND ST_Intersects(b.geom, a.rast)

-- przyklad 1 ST_AsRaster
CREATE TABLE poswietny.porto_parishes AS
WITH r AS ( --tabela tymaczasowa
	SELECT rast FROM rasters.dem
	LIMIT 1 -- wybor jednego rastra jako szablonu (rozdzielczosc, grid, SRID)
)
SELECT ST_AsRaster(a.geom, r.rast, '8BUI', a.id, -32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto'

--przyklad 2 ST_Union
DROP TABLE poswietny.porto_parishes;
CREATE TABLE poswietny.porto_parishes AS
WITH r AS (
	SELECT rast FROM rasters.dem
	LIMIT 1
)
SELECT ST_Union(ST_AsRaster(a.geom, r.rast, '8BUI', a.id, -32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto'
	
--przyklad 3 ST_Tile
DROP TABLE poswietny.porto_parishes;
CREATE TABLE poswietny.porto_parishes AS
WITH r AS (
	SELECT rast FROM rasters.dem
	LIMIT 1
)
SELECT ST_Tile(ST_Union(ST_AsRaster(a.geom, r.rast, '8BUI', a.id, -32767)), 128, 128, true, -32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto'

-- przyklad 1 ST_Intersection
CREATE TABLE poswietny.intersection AS
SELECT
a.rid, (ST_Intersection(b.geom, a.rast)).geom, (ST_Intersection(b.geom, a.rast)).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects (b.geom, a.rast);

-- przyklad 2 ST_DumpAsPolygons
CREATE TABLE poswietny.dumppolygons AS
SELECT
a.rid, (ST_DumpAsPolygons(ST_Clip(a.rast, b.geom))).geom, (ST_DumpAsPolygons(ST_Clip(a.rast, b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' AND ST_Intersects(b.geom, a.rast);


-- przyklad 1 ST_Band
CREATE TABLE poswietny.landsat_nir AS
SELECT rid, ST_BAND(rast,4) AS rast
FROM rasters.landsat8;

-- przyklad 2 ST_Clip
CREATE TABLE poswietny.paranhos_dem AS
SELECT a.rid, ST_Clip(a.rast, b.geom, true) AS rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

-- przyklad 3 ST_Slope
CREATE TABLE poswietny.paranhos_slope AS
SELECT a.rid, ST_Slope(a.rast,1,'32BF','PERCENTAGE') AS rast
FROM poswietny.paranhos_dem AS a;

-- przyklad 4 ST_Reclass
CREATE TABLE poswietny.paranhos_slope_reclass AS
SELECT a.rid, ST_Reclass(a.rast, 1, '(0-15]:1, (15-30]:2, (30-9999]:3', '32BF', 0)
FROM poswietny.paranhos_slope AS a;

-- przyklad 5 ST_SummaryStats
SELECT ST_SummaryStats(a.rast) AS stats
FROM poswietny.paranhos_dem AS a;
-- count, sum, mean, stddev,  min, max w takiej kolejnosci

-- przyklad 6 ST_SummaryStats oraz Union
SELECT ST_SummaryStats(ST_Union(a.rast))
FROM poswietny.paranhos_dem AS a;

-- przyklad 7 ST_SummaryStats z kontrolą danych
WITH t AS (
	SELECT ST_SummaryStats(ST_Union(a.rast)) AS stats
	FROM poswietny.paranhos_dem AS a
)
SELECT (stats).min, (stats).max, (stats).mean FROM t

-- przyklad 8 ST_SummaryStats i GROUP BY
WITH t AS (
	SELECT b.parish AS parish, ST_SummaryStats(ST_Union(ST_Clip(a.rast, b.geom, true))) AS stats
	FROM rasters.dem AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' AND ST_Intersects(b.geom, a.rast)
	GROUP BY b.parish
)
SELECT parish, (stats).min, (stats).max, (stats).mean FROM t

-- przyklad 9 ST_Value
SELECT b.name, ST_Value(a.rast, (ST_Dump(b.geom)).geom)
FROM rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast, b.geom)
ORDER BY b.name

--przyklad 10 ST_TPI
CREATE TABLE poswietny.tpi30 AS
SELECT ST_TPI(a.rast,1) AS rast
FROM rasters.dem a;
--30s

CREATE INDEX idx_tpi30_rast_gist ON poswietny.tpi30
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('poswietny' :: name, 'tpi30' :: name, 'rast' :: name);

-- przyklad samodzielny
CREATE TABLE poswietny.tpi30_porto AS
SELECT a.rid, ST_TPI(a.rast,1) AS rast
FROM rasters.dem a, vectors.porto_parishes b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';
-- 1.5s

-- przyklad 1 wyrazenie algerby map NDVI
CREATE TABLE poswietny.porto_ndvi AS
WITH r AS (
	SELECT a.rid, ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' AND ST_Intersects(b.geom, a.rast)
)
SELECT 
	r.rid, ST_MapAlgebra(
				r.rast, 1, 
				r.rast, 4,
				'([rast2.val] - [rast1.val]) / ([rast2.val] + [rast1.val])::float', '32BF') AS rast
FROM r;

CREATE INDEX idx_porto_ndvi_rast_gist ON poswietny.porto_ndvi
USING gist (ST_ConvexHULL(rast));

SELECT AddRasterConstraints('poswietny'::name, 'porto_ndvi'::name, 'rast'::name);

-- przyklad 2 funkcja zwrotna
CREATE OR REPLACE FUNCTION poswietny.ndvi (
	value double precision [] [] [],
	pos integer [] [],
	VARIADIC userargs text []
)
RETURNS double precision AS
$$ 
BEGIN
	--RAISE NOTICE 'Pixel Value: %', value [1][1][1]; --> For debug purposes
	RETURN (value [2][1][1] - value [1][1][1]) / (value [2][1][1] + value [1][1][1]); --> NDVI calculation
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

CREATE TABLE poswietny.porto_ndvi2 AS
WITH r AS (
	SELECT a.rid, ST_Clip(a.rast, b.geom, true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' AND ST_Intersects(b.geom, a.rast)
)
SELECT
	r.rid, ST_MapAlgebra(
			r.rast, ARRAY[1,4], 
			'poswietny.ndvi(double precision[],
			integer[], text[])' :: regprocedure, --> This is the function
			'32BF' :: text
	) AS rast
FROM r

CREATE INDEX idx_porto_ndvi2_rast_gist ON poswietny.porto_ndvi2
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('poswietny'::name, 'porto_ndvi2' :: name, 'rast' :: name);

-- przyklad 1 ST_AsTiff
SELECT ST_AsTiff(ST_Union(rast))
FROM poswietny.porto_ndvi;

-- przyklad 2 ST_AsGDALRaster
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=0'])
FROM poswietny.porto_ndvi;

SELECT  ST_GDALDrivers();

-- przyklad 3 zapis na dysku
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
		ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
		) AS loid
FROM poswietny.porto_ndvi;

SELECT lo_export(loid, 'C:\Windows\Temp\myraster.tiff')
FROM tmp_out;

-- przyklad 4 GDAL


-- przyklad 
CREATE TABLE poswietny.tpi30_porto AS
SELECT ST_TPI(a.rast,1) AS rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

CREATE INDEX idx_tpi30_porto_rast_gist ON poswietny.tpi30_porto
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('poswietny'::name, 'tpi30_porto'::name, 'rast'::name);
