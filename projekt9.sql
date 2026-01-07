CREATE TABLE rastry_union AS
SELECT
    1 as id,
    ST_Union(
        ST_SnapToGrid("rast", 0, 0), --wyrownanie rastrow do tej samej siatki pikseli
        'MAX' -- metoda laczenia pikseli, zeby wybierana byla najwieksza wartosc piksela w miejscach gdzie rastry sie nakladaja na siebie
    ) AS rast
FROM "Exports";

-- dodanie constraintów
SELECT AddRasterConstraints('rastry_union'::name, 'rast'::name);

-- tworzenie indeksow przestrzennych
CREATE INDEX raster_scal_idx ON rastry_union USING gist (ST_ConvexHull(rast));