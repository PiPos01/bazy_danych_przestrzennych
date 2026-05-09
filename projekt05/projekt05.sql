--CREATE EXTENSION postgis;


-- zadanie 1

DROP TABLE obiekty;

CREATE TABLE obiekty (
id INT PRIMARY KEY NOT NULL,
nazwa VARCHAR(10) NOT NULL,
geom GEOMETRY NOT NULL
); 

INSERT INTO obiekty VALUES
(1, 'obiekt1', ST_Union(ARRAY[ 
'LINESTRING(0 1, 1 1)', 
'CIRCULARSTRING(1 1, 2 0, 3 1)', 
'CIRCULARSTRING(3 1, 4 2, 5 1)', 
'LINESTRING(5 1, 6 1)'])),
(2, 'obiekt2', ST_UNION(ARRAY[
'LINESTRING(10 6, 14 6)', 
'CIRCULARSTRING(14 6, 16 4, 14 2)', 
'CIRCULARSTRING(14 2, 12 0, 10 2)',
'LINESTRING(10 2, 10 6)', 
'CIRCULARSTRING(11 2, 12 3, 13 2, 12 1, 11 2)'])),
(3, 'obiekt3', ST_GeomFromText('LINESTRING(7 15, 10 17, 12 13, 7 15)')),
(4, 'obiekt4', ST_GeomFromText('LINESTRING(20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5)')),
(5, 'obiekt5', ST_GeomFromText('MULTIPOINT((30 30 59), (38 32 234))')),
(6, 'obiekt6', ST_GeomFromText('GeometryCollection(LINESTRING(1 1, 3 2), POINT(4 2))'))

-- w QGIS wyświetli się pięc obiektów, ponieważ jeden z nich jest typem GeometryCollection, który nie jest wyświetlany w QGIS

-- zadanie 2
SELECT 
ST_Area(
	ST_Buffer(
		ST_ShortestLine(a.geom, b.geom),5
		)
	) AS powierzchnia_bufora
FROM obiekty a
INNER JOIN obiekty b
ON a.id = 3 AND b.id = 4


-- zadanie 3
-- warunek: linestring musi być domknięty, bo to jest cecha poligonu
UPDATE obiekty
SET geom = ST_GeomFromText('LINESTRING(20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5, 20 20)')
WHERE id = 4

UPDATE obiekty
set geom = ST_MakePolygon(geom)
WHERE id = 4

-- w jednym kroku
-- UPDATE  obiekty
-- SET geom = ST_MakePolygon(ST_GeomFromText('LINESTRING(20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5, 20 20)'))
-- WHERE id = 4

-- inna, lepsza wersja
-- UPDATE obiekty
--SET geom = ST_MakePolygon(ST_AddPoint(geom, ST_GeomFromText('POINT(20,20)')))
-- WHERE id = 4
-- zadanie 4
INSERT INTO obiekty (id, nazwa, geom)
SELECT 
	7 AS id,
	'obiekt7' AS nazwa,
	ST_Collect(a.geom, b.geom) AS geom
FROM obiekty a
INNER JOIN obiekty b
ON a.id = 3 AND b.id = 4

-- SELECT * FROM obiekty
-- SELECT ST_GeometryType(geom) FROM obiekty

-- zadanie 5
SELECT SUM(
		ST_AREA(
			ST_Buffer(geom, 5)
		)
)
FROM obiekty
WHERE ST_HasArc(geom) = FALSE
