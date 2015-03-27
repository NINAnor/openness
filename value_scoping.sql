CREATE TABLE openness.adresse_bygg ( 
adresse_id integer, 
kommune_nr integer, 
kommune_navn character varying(50), 
gatenavn character varying(50), 
gatenavnkode integer, 
husnummer integer, 
bokstav character varying(5), 
undernummer integer, 
post_nr integer, 
poststed  character varying(50), 
bygnings_nr integer, 
bygning_lnr integer, 
bygningstype_nr integer, 
bygningstype_navn character varying(50), 
bygningsstatus_nr character varying(50), 
bygningsstatus_navn character varying(50), 
tatt_i_bruk_dato character varying(50));

COPY openness.adresse_bygg(adresse_id,kommune_nr,kommune_navn,gatenavn,gatenavnkode,husnummer,bokstav,undernummer,post_nr,poststed,bygnings_nr,bygning_lnr,bygningstype_nr,bygningstype_navn,bygningsstatus_nr,bygningsstatus_navn,tatt_i_bruk_dato) 
FROM '/home/stefan/OpenNESS/2014_5_adresse_bygg_comma.csv'
WITH DELIMITER ','
CSV HEADER;

CREATE INDEX "openness.adresse_bygg_idx"
   ON openness.adresse_bygg USING btree (adresse_id ASC NULLS LAST);
ALTER TABLE openness.adresse_bygg
  CLUSTER ON "openness.adresse_bygg_idx";
CREATE INDEX "openness.adresse_bygg_postidx"
   ON openness.adresse_bygg USING btree (post_nr ASC NULLS LAST);
ALTER TABLE openness.adresse_bygg
  CLUSTER ON "openness.adresse_bygg_postidx";

CREATE TABLE openness.appartment_buildings_oslo AS
SELECT * FROM openness.adresse_bygg
WHERE bygningstype_navn IN ('Appartement', 
'Boligbrakker', 
'Store sammenb. boligbygg på 3 og 4 etg.', 
'Store sammenb. boligbygg på 5 etg. el. mer', 
'Store sammenbygde boligbygg på 2 etg.', 
'Stort frittliggende boligbygg på 2 etg.', 
'Stort frittliggende boligbygg på 3 og 4 etg.', 
'Stort frittliggende boligbygg på 5 etg. el. mer') AND kommune_nr = 301;

/* 'Enebolig', 
'Enebolig m/hybel/sokkelleil.', 
'Kjede/atriumhus', 
'Rekkehus', 
'Tomannsbolig. horisontaldelt', 
'Tomannsbolig. vertikaldelt', 
'Våningshus', 
'Våningshus. tomannsb./horisont.', 
'Våningshus. tomannsb./horisont.'
 */
CREATE INDEX "openness.appartment_buildings_oslo_idx"
   ON openness.appartment_buildings_oslo USING btree (adresse_id ASC NULLS LAST);
ALTER TABLE openness.appartment_buildings_oslo  CLUSTER ON "openness.appartment_buildings_oslo_idx";
CREATE INDEX "openness.appartment_buildings_oslo_postidx"
   ON openness.appartment_buildings_oslo USING btree (post_nr ASC NULLS LAST);
ALTER TABLE openness.appartment_buildings_oslo  CLUSTER ON "openness.appartment_buildings_oslo_postidx";

--Limit INFOLAND data to apartments in Oslo
CREATE TABLE openness.utm_32n_adresse_appartments_oslo AS SELECT
b.*, a.bygningstype_navn FROM
openness.appartment_buildings_oslo AS a INNER JOIN openness.utm_32n_adresse_bolig AS b ON (a.adresse_id = b."ADRESSE_ID")

--Stortinget

ST_Distance(a.geom, ST_PointFromText('POINT(597241.373 6643036.691)', 25832)) AS distance_stortinget, 

--prox_forest_500
DROP TABLE IF EXISTS openness.nv_prox_forest_500;
CREATE TABLE openness.nv_prox_forest_500 AS SELECT DISTINCT ON (a.geom,a."GNR",a."BNR",a."FNR",a."SNR",a."POSTNR",a."ETASJE_TYPE",a."ETASJE_NR",a."LEILIGHET_NR",a."GATENAVN_KODE",a."HUSNR",a."BOKSTAV",a."UNDERNR")
a.*, ST_Distance(a.geom, ST_PointFromText('POINT(597241.373 6643036.691)', 25832)) AS distance_stortinget, ST_Distance(a.geom,b.geom) AS distance, CAST('prox_forest_500' AS varchar) AS bg_variable, (500 - ST_Distance(a.geom,b.geom)) *  290.63 AS marginal_effect_nok
FROM
openness.utm_32n_adresse_appartments_oslo AS a,
openness.markagrensa AS b
WHERE ST_DWithin(a.geom,b.geom,500)
ORDER BY a.geom,a."GNR",a."BNR",a."FNR",a."SNR",a."POSTNR",a."ETASJE_TYPE",a."ETASJE_NR",a."LEILIGHET_NR",a."GATENAVN_KODE",a."HUSNR",a."BOKSTAV",a."UNDERNR", ST_Distance(a.geom,b.geom);

--prox_fjord_1000
DROP TABLE IF EXISTS openness.nv_prox_fjord_1000;
CREATE TABLE openness.nv_prox_fjord_1000 AS SELECT DISTINCT ON (a.geom,a."GNR",a."BNR",a."FNR",a."SNR",a."POSTNR",a."ETASJE_TYPE",a."ETASJE_NR",a."LEILIGHET_NR",a."GATENAVN_KODE",a."HUSNR",a."BOKSTAV",a."UNDERNR")
a.*, ST_Distance(a.geom, ST_PointFromText('POINT(597241.373 6643036.691)', 25832)) AS distance_stortinget, ST_Distance(a.geom,b.geom) AS distance, CAST('prox_fjord_1000' AS varchar) AS bg_variable, (1000 - ST_Distance(a.geom,b.geom)) *  441.24 AS marginal_effect_nok
FROM
openness.utm_32n_adresse_appartments_oslo AS a,
openness.fjordgrensa AS b
WHERE ST_DWithin(a.geom,b.geom,1000)
ORDER BY a.geom,a."GNR",a."BNR",a."FNR",a."SNR",a."POSTNR",a."ETASJE_TYPE",a."ETASJE_NR",a."LEILIGHET_NR",a."GATENAVN_KODE",a."HUSNR",a."BOKSTAV",a."UNDERNR", ST_Distance(a.geom,b.geom);

--prox_fjord_100
DROP TABLE IF EXISTS openness.nv_prox_fjord_100;
CREATE TABLE openness.nv_prox_fjord_100 AS SELECT DISTINCT ON (a.geom,a."GNR",a."BNR",a."FNR",a."SNR",a."POSTNR",a."ETASJE_TYPE",a."ETASJE_NR",a."LEILIGHET_NR",a."GATENAVN_KODE",a."HUSNR",a."BOKSTAV",a."UNDERNR")
a.*, ST_Distance(a.geom, ST_PointFromText('POINT(597241.373 6643036.691)', 25832)) AS distance_stortinget, ST_Distance(a.geom,b.geom) AS distance, CAST('prox_fjord_100' AS varchar) AS bg_variable,  410552.87 AS marginal_effect_nok
FROM
openness.utm_32n_adresse_appartments_oslo AS a,
openness.arealer_ved_fjorden AS b
WHERE ST_DWithin(a.geom,b.geom,100)
ORDER BY a.geom,a."GNR",a."BNR",a."FNR",a."SNR",a."POSTNR",a."ETASJE_TYPE",a."ETASJE_NR",a."LEILIGHET_NR",a."GATENAVN_KODE",a."HUSNR",a."BOKSTAV",a."UNDERNR", ST_Distance(a.geom,b.geom);

--prox_park_500
DROP TABLE IF EXISTS openness.nv_prox_park_500;
CREATE TABLE openness.nv_prox_park_500 AS SELECT DISTINCT ON (a.geom,a."GNR",a."BNR",a."FNR",a."SNR",a."POSTNR",a."ETASJE_TYPE",a."ETASJE_NR",a."LEILIGHET_NR",a."GATENAVN_KODE",a."HUSNR",a."BOKSTAV",a."UNDERNR")
a.*, ST_Distance(a.geom, ST_PointFromText('POINT(597241.373 6643036.691)', 25832)) AS distance_stortinget, ST_Distance(a.geom,b.geom) AS distance, CAST('prox_park_500' AS varchar) AS bg_variable, (500 - ST_Distance(a.geom,b.geom)) * 263.90 AS marginal_effect_nok
FROM
openness.utm_32n_adresse_appartments_oslo AS a,
openness.parker AS b
WHERE ST_DWithin(a.geom,b.geom,500)
ORDER BY a.geom,a."GNR",a."BNR",a."FNR",a."SNR",a."POSTNR",a."ETASJE_TYPE",a."ETASJE_NR",a."LEILIGHET_NR",a."GATENAVN_KODE",a."HUSNR",a."BOKSTAV",a."UNDERNR", ST_Distance(a.geom,b.geom);

--large_park
DROP TABLE IF EXISTS openness.nv_large_park;
CREATE TABLE openness.nv_large_park AS SELECT DISTINCT ON (a.geom,a."GNR",a."BNR",a."FNR",a."SNR",a."POSTNR",a."ETASJE_TYPE",a."ETASJE_NR",a."LEILIGHET_NR",a."GATENAVN_KODE",a."HUSNR",a."BOKSTAV",a."UNDERNR")
a.*, ST_Distance(a.geom, ST_PointFromText('POINT(597241.373 6643036.691)', 25832)) AS distance_stortinget, ST_Distance(a.geom,b.geom) AS distance, CAST('large_park' AS varchar) AS bg_variable, CASE WHEN ST_Area(b.geom) > 100000 THEN 41502.11 ELSE 0 END AS marginal_effect_nok
FROM
openness.utm_32n_adresse_appartments_oslo AS a,
openness.parker AS b
WHERE ST_DWithin(a.geom,b.geom,500)
ORDER BY a.geom,a."GNR",a."BNR",a."FNR",a."SNR",a."POSTNR",a."ETASJE_TYPE",a."ETASJE_NR",a."LEILIGHET_NR",a."GATENAVN_KODE",a."HUSNR",a."BOKSTAV",a."UNDERNR", b.gid, ST_Distance(a.geom,b.geom);
 
--prox_graveyard_500
DROP TABLE IF EXISTS openness.nv_prox_graveyard_500;
CREATE TABLE openness.nv_prox_graveyard_500 AS SELECT DISTINCT ON (a.geom,a."GNR",a."BNR",a."FNR",a."SNR",a."POSTNR",a."ETASJE_TYPE",a."ETASJE_NR",a."LEILIGHET_NR",a."GATENAVN_KODE",a."HUSNR",a."BOKSTAV",a."UNDERNR")
a.*, ST_Distance(a.geom, ST_PointFromText('POINT(597241.373 6643036.691)', 25832)) AS distance_stortinget, ST_Distance(a.geom,b.geom) AS distance, CAST('prox_graveyard_500' AS varchar) AS bg_variable, (500 - ST_Distance(a.geom,b.geom)) * 355.66 AS marginal_effect_nok
FROM
openness.utm_32n_adresse_appartments_oslo AS a,
openness.gravlunder_oslo AS b
WHERE ST_DWithin(a.geom,b.geom,500)
ORDER BY a.geom,a."GNR",a."BNR",a."FNR",a."SNR",a."POSTNR",a."ETASJE_TYPE",a."ETASJE_NR",a."LEILIGHET_NR",a."GATENAVN_KODE",a."HUSNR",a."BOKSTAV",a."UNDERNR", ST_Distance(a.geom,b.geom);

--freshwater_200
DROP TABLE IF EXISTS openness.nv_prox_freshwater_200;
CREATE TABLE openness.nv_prox_freshwater_200 AS SELECT DISTINCT ON (a.geom,a."GNR",a."BNR",a."FNR",a."SNR",a."POSTNR",a."ETASJE_TYPE",a."ETASJE_NR",a."LEILIGHET_NR",a."GATENAVN_KODE",a."HUSNR",a."BOKSTAV",a."UNDERNR")
a.*, ST_Distance(a.geom, ST_PointFromText('POINT(597241.373 6643036.691)', 25832)) AS distance_stortinget, ST_Distance(a.geom,b.geom) AS distance, CAST('freshwater_200' AS varchar) AS bg_variable, 86836.42 AS marginal_effect_nok
FROM
openness.utm_32n_adresse_appartments_oslo AS a,
openness.arealer_med_ferskvann AS b
WHERE ST_DWithin(a.geom,b.geom,200)
ORDER BY a.geom,a."GNR",a."BNR",a."FNR",a."SNR",a."POSTNR",a."ETASJE_TYPE",a."ETASJE_NR",a."LEILIGHET_NR",a."GATENAVN_KODE",a."HUSNR",a."BOKSTAV",a."UNDERNR", ST_Distance(a.geom,b.geom);

--pc_green_500
DROP TABLE IF EXISTS openness.nv_pc_green_500;
CREATE TABLE openness.nv_pc_green_500 AS 
SELECT
a.*, ST_Distance(a.geom, ST_PointFromText('POINT(597241.373 6643036.691)', 25832)) AS distance_stortinget, sum(ST_Area(ST_Intersection(ST_Buffer(a.geom,500), b.geom))/(pi()*250000)) AS pc_green, CAST('pc_green_500' AS varchar) AS bg_variable, sum(ST_Area(ST_Intersection(ST_Buffer(a.geom,500), b.geom))/(pi()*250000)) AS check, sum((ST_Area(ST_Intersection(ST_Buffer(a.geom,500), b.geom))/(pi()*250000)) * -11930.85) AS marginal_effect_nok
FROM
openness.utm_32n_adresse_appartments_oslo AS a,
(SELECT ST_MakeValid(geom) AS geom FROM openness.frimorader_alle) AS b
WHERE ST_DWithin(a.geom,b.geom,500)
GROUP BY a.id, a."X_KOORD", a."Y_KOORD", a."Z_KOORD", a."ADRESSE_TYPE", a."GATENAVN", a.geom, a.bygningstype_navn, a."ADRESSE_ID", a."KOMMUNE_NR", a."GNR",a."BNR",a."FNR",a."SNR",a."POSTNR",a."ETASJE_TYPE",a."ETASJE_NR",a."LEILIGHET_NR",a."GATENAVN_KODE",a."HUSNR",a."BOKSTAV",a."UNDERNR", bg_variable;

ALTER TABLE openness.nv_pc_green_500 DROP COLUMN "check";

SELECT bg_variable, sum(marginal_effect_nok) / 1000000 AS marginal_effect_sum_mio_nok, count(xa.id) AS number_appartments FROM
(
SELECT * FROM openness.nv_prox_forest_500 UNION ALL
SELECT * FROM openness.nv_prox_fjord_1000 UNION ALL
SELECT * FROM openness.nv_prox_fjord_100 UNION ALL
SELECT * FROM openness.nv_prox_park_500 UNION ALL
SELECT * FROM openness.nv_large_park WHERE marginal_effect_nok > 0 UNION ALL
SELECT * FROM openness.nv_prox_graveyard_500 UNION ALL
SELECT * FROM openness.nv_prox_freshwater_200 UNION ALL
SELECT * FROM openness.nv_pc_green_500
) AS xa
GROUP BY bg_variable
ORDER BY marginal_effect_sum_mio_nok;

SELECT id, distance_stortinget, sum(marginal_effect_nok) / 1000000 AS marginal_effect_sum_mio_nok FROM
(
SELECT * FROM openness.nv_prox_forest_500 UNION ALL
SELECT * FROM openness.nv_prox_fjord_1000 UNION ALL
SELECT * FROM openness.nv_prox_fjord_100 UNION ALL
SELECT * FROM openness.nv_prox_park_500 UNION ALL
SELECT * FROM openness.nv_large_park WHERE marginal_effect_nok > 0 UNION ALL
SELECT * FROM openness.nv_prox_graveyard_500 UNION ALL
SELECT * FROM openness.nv_prox_freshwater_200 UNION ALL
SELECT * FROM openness.nv_pc_green_500
) AS xa
GROUP BY id, distance_stortinget
ORDER BY distance_stortinget;

SELECT * FROM
count(a.geom) AS number_of_flats, ST_Area(b.geom)/10000 AS buffer_area_1000m_ha, b.type, b.navn
FROM
(SELECT * FROM openness.adresse_bygg
WHERE bygningstype_navn IN ('Appartement', 
'Boligbrakker', 
'Store sammenb. boligbygg på 3 og 4 etg.', 
'Store sammenb. boligbygg på 5 etg. el. mer', 
'Store sammenbygde boligbygg på 2 etg.', 
'Stort frittliggende boligbygg på 2 etg.', 
'Stort frittliggende boligbygg på 3 og 4 etg.', 
'Stort frittliggende boligbygg på 5 etg. el. mer',
'Enebolig',
'Enebolig m/hybel/sokkelleil.', 
'Kjede/atriumhus', 
'Rekkehus', 
'Tomannsbolig. horisontaldelt', 
'Tomannsbolig. vertikaldelt', 
'Våningshus', 
'Våningshus. tomannsb./horisont.', 
'Våningshus. tomannsb./horisont.'
) AND kommune_nr = 301) AS a,
(SELECT ST_Buffer(ST_MakeValid(geom), 1000) AS geom FROM openness.frimorader_alle) AS b
WHERE ST_Intersects(a.geom, b.geom)
GROUP BY b.navn, b.type, b.navn

CREATE TABLE openness.housing_units_oslo AS
SELECT * FROM openness.adresse_bygg
WHERE bygningstype_navn IN ('Appartement', 
'Boligbrakker', 
'Store sammenb. boligbygg på 3 og 4 etg.', 
'Store sammenb. boligbygg på 5 etg. el. mer', 
'Store sammenbygde boligbygg på 2 etg.', 
'Stort frittliggende boligbygg på 2 etg.', 
'Stort frittliggende boligbygg på 3 og 4 etg.', 
'Stort frittliggende boligbygg på 5 etg. el. mer',
'Enebolig',
'Enebolig m/hybel/sokkelleil.', 
'Kjede/atriumhus', 
'Rekkehus', 
'Tomannsbolig. horisontaldelt', 
'Tomannsbolig. vertikaldelt', 
'Våningshus', 
'Våningshus. tomannsb./horisont.', 
'Våningshus. tomannsb./horisont.'
) AND kommune_nr = 301

CREATE INDEX "openness.housing_units_oslo_idx"
   ON openness.housing_units_oslo USING btree (adresse_id ASC NULLS LAST);
ALTER TABLE openness.housing_units_oslo  CLUSTER ON "openness.housing_units_oslo_idx";
CREATE INDEX "openness.housing_units_oslo_postidx"
   ON openness.housing_units_oslo USING btree (post_nr ASC NULLS LAST);
ALTER TABLE openness.housing_units_oslo  CLUSTER ON "openness.housing_units_oslo_postidx";


--ORDER BY DATE!!! for postnr
DROP TABLE openness.utm_32n_adresse_housing_units_oslo;
CREATE TABLE openness.utm_32n_adresse_housing_units_oslo AS SELECT  DISTINCT ON (b.geom,b."GNR",b."BNR",b."FNR",b."SNR",b."POSTNR",b."ETASJE_TYPE",b."ETASJE_NR",b."LEILIGHET_NR",b."GATENAVN_KODE",b."HUSNR",b."BOKSTAV",b."UNDERNR")
b.*, a.bygningstype_navn FROM
openness.housing_units_oslo AS a INNER JOIN openness.utm_32n_adresse_bolig AS b ON (a.adresse_id = b."ADRESSE_ID");

CREATE INDEX "openness.utm_32n_adresse_housing_units_oslo_spidx"
   ON openness.utm_32n_adresse_housing_units_oslo USING gist (geom);
ALTER TABLE openness.utm_32n_adresse_housing_units_oslo  CLUSTER ON "openness.utm_32n_adresse_housing_units_oslo_spidx";


DROP TABLE openness.residental_buildings;
CREATE TABLE openness.residental_buildings AS
SELECT DISTINCT ON (adresse_id) * FROM (SELECT * FROM openness.adresse_bygg
WHERE bygningstype_navn IN ('Appartement', 
'Boligbrakker', 
'Store sammenb. boligbygg på 3 og 4 etg.', 
'Store sammenb. boligbygg på 5 etg. el. mer', 
'Store sammenbygde boligbygg på 2 etg.', 
'Stort frittliggende boligbygg på 2 etg.', 
'Stort frittliggende boligbygg på 3 og 4 etg.', 
'Stort frittliggende boligbygg på 5 etg. el. mer',
'Enebolig', 
'Enebolig m/hybel/sokkelleil.', 
'Kjede/atriumhus', 
'Rekkehus', 
'Tomannsbolig. horisontaldelt', 
'Tomannsbolig. vertikaldelt', 
'Våningshus', 
'Våningshus. tomannsb./horisont.', 
'Våningshus. tomannsb./horisont.') ) AS a INNER JOIN openness.utm_32n_adresse_bolig AS b ON (a.adresse_id = b."ADRESSE_ID");
