#!/bin/bash

#Import original data
shp2pgsql -s EPSG:25832 -d -D -I -W Latin4 ~/R_Prosjekter/OpenNESS/GIS/Utvalgte\ Eiendommer/xy_leiligheter_utvalg_7.shp openness.xy_leiligheter_utvalg_7 | psql -d gisdata
shp2pgsql -s EPSG:25832 -d -D -I -W Latin4 ~/R_Prosjekter/OpenNESS/GIS/Utvalgte\ Eiendommer/xy_houses_and_apartments.shp openness.xy_houses_and_apartments | psql -d gisdata
ogr2ogr -progress --config PG_USE_COPY YES -overwrite -a_srs EPSG:25832 -f "PostgreSQL" -lco FID=gid -lco GEOMETRY_NAME=geom -nln trees_oslo "PG:dbname=gisdata active_schema=openness"  ~/R_Prosjekter/OpenNESS/GIS/Tree\ database/Trees_5_50-2015-03-25-1500/Trees_5_40_U.sqlite trees_5_40_u

psql -d gisdata -c "ALTER TABLE openness.trees_oslo CLUSTER ON trees_oslo_geom_geom_idx;"
psql -d gisdata -c "VACUUM FULL ANALYZE openness.trees_oslo;"

#Convert trees to KML (after the shape file was exported to sqlite from within QGIS
ogr2ogr -progress -overwrite -s_srs EPSG:25832 -t_srs EPSG:4326 -f "KML" -lco NameField=gid -lco DescriptionField=height ~/R_Prosjekter/OpenNESS/GIS/Tree\ database/Trees_5_40_U.kml "PG:dbname=gisdata active_schema=openness"  trees_oslo
cat  /home/stefan/R_Prosjekter/OpenNESS/GIS/Tree\ database/Trees_5_40_U_pg.kml | grep -v ExtendedData | grep -v Schema | grep -v Folder > /home/stefan/R_Prosjekter/OpenNESS/GIS/Tree\ database/Trees_5_40_U.kml

#Create temporary table with number of inhabitant by SSB grid cell divided by number of housing units in that grid cell
psql -d gisdata -c "CREATE TABLE openness.pop_2014_tmp AS SELECT unnest(aid) AS adresse_id, people_per_hu FROM 
(SELECT array_agg(a.adresse_id) aid, CAST(b.antall_10 AS double precision) / CAST(count(a.adresse_id) AS double precision) AS people_per_hu, b.ssbid FROM 
  openness.residental_buildings AS a, 
  (SELECT ssbid, geom, antall_10 FROM
    ssb_data_utm33n.ssb_250m NATURAL INNER JOIN 
    ssb_data_utm33n.population_250m_2014) AS b 
  WHERE ST_Intersects(ST_Transform(a.geom, 25833), b.geom)
  GROUP BY b.ssbid, b.antall_10) AS x;"

psql -d gisdata -c "CREATE INDEX openness_pop_2014_tmp_adresse_id ON openness.pop_2014_tmp(adresse_id);"
psql -d gisdata -c "ALTER TABLE openness.pop_2014_tmp CLUSTER ON openness_pop_2014_tmp_adresse_id;"
psql -d gisdata -c "VACUUM FULL ANALYZE openness.pop_2014_tmp;"
	
#Create table with number of inhabitants per housing units (based on SSB grid cell)
psql -d gisdata -c "CREATE TABLE openness.pop_2014 AS SELECT a.*, b.people_per_hu FROM
  openness.residental_buildings AS a NATURAL LEFT JOIN
  openness.pop_2014_tmp AS b;"

psql -d gisdata -c "ALTER TABLE openness.pop_2014 ADD CONSTRAINT openness_pop_2014_pkey PRIMARY KEY (adresse_id);"
psql -d gisdata -c "CREATE INDEX openness_pop_2014_spidx ON openness.pop_2014 USING gist (geom);"
psql -d gisdata -c "ALTER TABLE openness.pop_2014 CLUSTER ON openness_pop_2014_spidx;"
psql -d gisdata -c "VACUUM FULL ANALYZE openness.pop_2014;"

#Remove temporary table
psql -d gisdata -c "DROP TABLE openness.pop_2014_tmp;"
#----------- Noras subset of flats
psql -d gisdata -c "ALTER TABLE openness.xy_leiligheter_utvalg_7 ADD COLUMN number_trees_500m integer;";
psql -d gisdata -c "UPDATE openness.xy_leiligheter_utvalg_7 SET number_trees_500m = x.number_trees_500m FROM (SELECT a.gid, count(b.gid) AS number_trees_500m FROM
	openness.xy_leiligheter_utvalg_7 AS a,
	openness.trees_oslo AS b
WHERE ST_DWithin(a.geom, b.geom, 500) GROUP BY a.gid) AS x WHERE xy_leiligheter_utvalg_7.gid = x.gid;"

#----------- Noras subset of houses and appartments
psql -d gisdata -c "ALTER TABLE openness.xy_houses_and_apartments ADD COLUMN number_trees_500m integer;";
psql -d gisdata -c "UPDATE openness.xy_houses_and_apartments SET number_trees_500m = x.number_trees_500m FROM (SELECT a.gid, count(b.gid) AS number_trees_500m FROM
	openness.xy_houses_and_apartments AS a,
	openness.trees_oslo AS b
WHERE ST_DWithin(a.geom, b.geom, 500) GROUP BY a.gid) AS x WHERE xy_houses_and_apartments.gid = x.gid;"

#----------- flats in Oslo
psql -d gisdata -c "ALTER TABLE openness.utm_32n_adresse_appartments_oslo ADD COLUMN number_trees_500m integer;";
psql -d gisdata -c "UPDATE openness.utm_32n_adresse_appartments_oslo SET number_trees_500m = x.number_trees_500m FROM (SELECT a.id, count(b.gid) AS number_trees_500m FROM
	openness.utm_32n_adresse_appartments_oslo AS a,
	openness.trees_oslo AS b
WHERE ST_DWithin(a.geom, b.geom, 500) GROUP BY a.id) AS x WHERE utm_32n_adresse_appartments_oslo.id = x.id;"

#----------- All houses and appartments in Oslo
psql -d gisdata -c "ALTER TABLE openness.utm_32n_adresse_housing_units_oslo ADD COLUMN number_trees_500m integer;";
psql -d gisdata -c "UPDATE openness.utm_32n_adresse_housing_units_oslo SET number_trees_500m = x.number_trees_500m FROM (SELECT a.id, count(b.gid) AS number_trees_500m FROM
	openness.utm_32n_adresse_housing_units_oslo AS a,
	openness.trees_oslo AS b
WHERE ST_DWithin(a.geom, b.geom, 500) GROUP BY a.id) AS x WHERE utm_32n_adresse_housing_units_oslo.id = x.id;"


#Export data
ogr2ogr -progress ~/R_Prosjekter/OpenNESS/GIS/ssb_250m_population_2014.shp "PG:dbname=gisdata" ssb_data_utm33n.ssb_250m_population_2014
ogr2ogr -progress -overwrite -a_srs EPSG:25832 ~/R_Prosjekter/OpenNESS/GIS/population_2014_ssb_reidental_buildings.shp "PG:dbname=gisdata" openness.pop_2014
ogr2ogr -progress -overwrite -a_srs EPSG:25832 ~/R_Prosjekter/OpenNESS/GIS/xy_houses_and_apartments_trees.shp "PG:dbname=gisdata" openness.xy_houses_and_apartments
ogr2ogr -progress -overwrite -a_srs EPSG:25832 ~/R_Prosjekter/OpenNESS/GIS/xy_leiligheter_utvalg_7_trees.shp "PG:dbname=gisdata" openness.xy_leiligheter_utvalg_7

