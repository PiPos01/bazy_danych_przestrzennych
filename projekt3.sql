create extension postgis

-- zadanie 1
SELECT *
FROM t2019_kar_buildings b19
LEFT JOIN t2018_kar_buildings b18
ON b19.polygon_id=b18.polygon_id
WHERE b18.polygon_id IS NULL
OR b19.height <> b18.height
OR NOT ST_Equals(b19.geom, b18.geom);


-- SELECT * FROM points19


-- zadanie 2
-- utworzenie tabeli tymczasowej z zmienionymi budynkami w ciągu roku (2018-2019)
WITH 
changed_buildings AS(
SELECT b19.gid, b19.type, ST_Transform(ST_SetSRID(b19.geom, 4326), 3068) as geom
FROM t2019_kar_buildings b19
LEFT JOIN t2018_kar_buildings b18
ON b19.polygon_id=b18.polygon_id
WHERE b18.polygon_id IS NULL
OR b19.height <> b18.height
OR NOT ST_Equals(b19.geom, b18.geom)
),

-- utworzenie tabeli tymczasowej z nowymi POI powstałymi w ciągu roku 2018-2019
-- w SELECT musimy dokonać transformacji układu 0, na układ metrowy 3068 (ważne do funkcji ST_DWithin)
new_pois AS(
SELECT poi19.gid, poi19.type, ST_Transform(ST_SetSRID(poi19.geom, 4326), 3068) as geom
FROM t2019_kar_poi_table poi19
LEFT JOIN t2018_kar_poi_table poi18
ON poi19.gid=poi18.gid
WHERE poi18.gid IS NULL
)

SELECT COUNT(DISTINCT np.gid) as count, np.type
FROM new_pois np, changed_buildings cb
WHERE ST_DWithin(cb.geom,np.geom, 500)
GROUP BY np.type;


-- zadanie 3
-- SELECT * FROM t2019_kar_streets
-- DROP TABLE streets_reprojected

CREATE TABLE streets_reprojected AS
SELECT * FROM t2019_kar_streets;

-- sprawdzanie SRIDa tabeli
SELECT DISTINCT ST_SRID(geom) FROM streets_reprojected;

-- update SRIDa
UPDATE streets_reprojected SET geom = ST_Transform(ST_SetSRID(geom,4326),3068);

-- sprawdzenie tabeli po transformacji układu
SELECT DISTINCT ST_SRID(geom) FROM streets_reprojected;
-- SELECT ST_AsText(geom) FROM streets_reprojected


-- zadanie 4
-- DROP TABLE input_table
-- tworzenie tabeli input_table
CREATE TABLE input_table
(id INT PRIMARY KEY not null,
name VARCHAR(2),
geom GEOMETRY(Point)
);

INSERT INTO input_table VALUES
(1, 'P1', ST_GeomFromText('POINT(8.36093 49.03174)')),
(2, 'P2', ST_GeomFromText('POINT(8.39876 49.00644)'));

SELECT * FROM input_table;
-- sprawdzenie SRIDa
SELECT DISTINCT ST_SRID(geom) FROM input_table;


-- zadanie 5
-- zmiana SRIDa 
UPDATE input_table SET geom = ST_Transform(ST_SetSRID(geom,4326),3068);
-- sprawdzanie SRIDa po update'cie
SELECT DISTINCT ST_SRID(geom) FROM input_table;
-- SELECT ST_AsText(geom) FROM input_table


-- zadanie 6
WITH input_lines AS (
SELECT ST_MakeLine(geom) AS geom
FROM input_table
)

-- obie tabele musza byc w tym samym, metrowym SRIDzie
-- sprawdzamy SRID, czyli Spatial Reference Indetifier
-- SELECT DISTINCT ST_SRID(geom) FROM street_node19
-- transformacja
-- UPDATE t2019_kar_street_node SET geom=ST_Transform(ST_SetSrid(geom, 4326),3068)

-- sprawdzanie SRIDa po update'cie
-- SELECT DISTINCT ST_SRID(geom) FROM input_lines;
-- SELECT DISTINCT ST_SRID(geom) FROM t2019_kar_street_node;

SELECT sn.*
FROM t2019_kar_street_node sn, input_lines l
WHERE ST_DWithin(sn.geom, l.geom, 200) AND sn.intersect = 'Y';


-- zadanie 7
-- SELECT * FROM points19
-- SELECT * FROM land_use_a19

UPDATE t2019_kar_poi_table SET geom=ST_Transform(ST_SetSrid(geom, 4326),3068);
UPDATE t2019_kar_land_use_a SET geom=ST_Transform(ST_SetSrid(geom, 4326),3068);

SELECT DISTINCT COUNT( DISTINCT poi19.gid) as sporting_stores_near_parks
FROM t2019_kar_poi_table poi19, t2019_kar_land_use_a lu19
WHERE (ST_DWithin(poi19.geom, lu19.geom,300) AND poi19.type = 'Sporting Goods Store' AND lu19.type LIKE 'Park%');


-- zadanie 8
-- SELECT * FROM railways19
-- SELECT * FROM water_lines19

CREATE TABLE T_2019_KAR_BRIDGES
(id SERIAL PRIMARY KEY,
geom GEOMETRY(Point)
);

-- DROP TABLE T_2019_KAR_BRIDGES
-- wstawianie danych do kolumny geom
INSERT INTO T_2019_KAR_BRIDGES (geom)
SELECT DISTINCT ST_Intersection(r19.geom, wl19.geom) AS intersection_point
FROM t2019_kar_railways r19, t2019_kar_water_lines wl19
WHERE ST_Intersects(r19.geom, wl19.geom);

-- ST_Intersection => zwraca geometrie wspolna dla obu obiektow, tu punkt przeciecia
-- ST_Intersects => warunek logiczny, po to, aby uzyskac tylko wartosci TRUE z przecieciami
SELECT * FROM T_2019_KAR_BRIDGES