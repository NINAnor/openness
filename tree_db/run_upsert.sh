#!/bin/bash

ogr2ogr -progress -a_srs EPSG:25832 -nln trees_laser_cleaned_oslo_l -f PostgreSQL "PG:dbname=gisdata active_schema=openness_tree_db" /Prosjekter/OpenNESS/TREE\ VALUATION/Tree_DB_Tablet_Lisa/trees_laser_cleaned_oslo.sqlite trees_laser_cleaned_oslo
ogr2ogr -progress -a_srs EPSG:25832 -nln trees_laser_cleaned_oslo_lf -f PostgreSQL "PG:dbname=gisdata active_schema=openness_tree_db" /Prosjekter/OpenNESS/TREE\ VALUATION/Tree_DB_Tablet_Friederike/trees_laser_cleaned_oslo.sqlite trees_laser_cleaned_oslo
psql -d gisdata -f upsert_tree_db_flom_local_copy.sql
