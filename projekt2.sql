CREATE TABLE buildings (
id INT PRIMARY KEY NOT NULL,
geometry GEOMETRY,
name VARCHAR(20)
);

CREATE TABLE roads (
id INT PRIMARY KEY NOT NULL,
geometry GEOMETRY,
name VARCHAR(5)
);

CREATE TABLE points (
id INT PRIMARY KEY NOT NULL,
geometry GEOMETRY,
name VARCHAR(1)
);

INSERT INTO buildings VALUES 
(1, ST_GeometryFromText('POLYGON((8 4, 10.5 4, 10.5 1.5, 8 1.5, 8 4))'), 'BuildingA'),
(2, ST_GeometryFromText('POLYGON((4 5, 4 7, 6 7, 6 5, 4 5))'), 'BuildingB'),
(3, ST_GeometryFromText('POLYGON((3 8, 5 8, 5 6, 3 6, 3 8))'), 'BuildingC'),
(4, ST_GeometryFromText('POLYGON((9 9, 10 9, 10 8, 9 8, 9 9))'), 'BuildingD'),
(5, ST_GeometryFromText('POLYGON((1 2, 2 2, 2 1, 1 1, 1 2))'), 'BuildingE');

INSERT INTO roads VALUES
(1, ST_GeometryFromText('LINESTRING(7.5 10.5, 7.5 0)'), 'RoadY'),
(2, ST_GeometryFromText('LINESTRING(0 4.5, 12 4.5)'), 'RoadX');

INSERT INTO points VALUES
(1, ST_GeometryFromText('POINT(1 3.5)'), 'G'),
(2, ST_GeometryFromText('POINT(5.5 1.5)'), 'H'),
(3, ST_GeometryFromText('POINT(9 5.6)'), 'I'),
(4, ST_GeometryFromText('POINT(6 5.6)'), 'J'),
(5, ST_GeometryFromText('POINT(6 9.5)'), 'K');

-- zadanie a
SELECT SUM(ST_LENGTH(geometry)) as calkowita_dlugosc
FROM roads

-- zadanie b
SELECT ST_AsText(geometry) as WKT, ST_Area(geometry) as pole, ST_Perimeter(geometry) as obwod
FROM buildings
WHERE name='BuildingA'

-- zadanie c
SELECT name, ST_Area(geometry) as pole
FROM buildings
ORDER BY name ASC

-- zadanie d
SELECT name, ST_Perimeter(geometry) as obwody
FROM buildings
ORDER BY ST_Area(geometry) DESC
LIMIT 2

-- zadanie e
SELECT ST_DISTANCE(b.geometry, p.geometry) AS najkrotsza_odleglosc
FROM buildings b, points p
WHERE b.name='BuildingC' and p.name='K'

-- zadanie f
SELECT ST_Area(ST_Difference(b1.geometry, ST_Buffer(b2.geometry, 0.5))) as pole
FROM buildings b1, buildings b2
WHERE b1.name='BuildingC' and b2.name='BuildingB'

-- zadanie g
SELECT b.id, b.name
FROM buildings b, roads r
WHERE r.name='RoadX' AND ST_Y(ST_Centroid(b.geometry)) > ST_Y(ST_Centroid(r.geometry))
-- centroid musi być PUNKTEM, dlatego w drodze uzywamy polecenia centroid, zeby otrzymać jeden punkt dla linii

-- zadanie h
SELECT ST_Area(b.geometry) as pole_C, ST_Area(ST_GeometryFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))')) as pole_poligon,
ST_Area(ST_INTERSECTION(b.geometry, ST_GeometryFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))'))) as czesc_wspolna,
ST_Area(ST_Union(b.geometry, ST_GeometryFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))'))) as pole_union,
ST_Area(ST_Difference(ST_Union(b.geometry, ST_GeometryFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))')), 
ST_INTERSECTION(b.geometry, ST_GeometryFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))')))) as pole_bez_czesci_wspolnej
FROM buildings b

WHERE b.name='BuildingC'
