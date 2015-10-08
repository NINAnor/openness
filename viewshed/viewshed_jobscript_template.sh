#!/bin/bash
#
#############################################################################
# AUTHOR(S): Stefan Blumentrath
# PURPOSE: Calculate viewsheds for houses in Oslo
# COPYRIGHT: (C) 2015 by the Stefan Blumentrath
#
# This script is just a template for production of jobscripts for chunks of
# houses, so they can be run in parallel in individual mapsets (using xargs)
# 
# Generate and run jobscripts by executing "run_parallel_jobscripts.sh creation script.
# run jobscript as GRASS 7.0 batch job
#
# This program is free software under the GNU General Public
# License (>=v2). Read the file COPYING that comes with GRASS
# for details.
#############################################################################
#
###########
### To Do:
### Replace dummy house_boundaries URL with propper house_boundaries URL
### Check if points in v.to.points inherit attributes from lines!!!
### Replace dummy map name for DSM by propper map name
### Check if path to SQLite DBs for viewsheds is correct and create it if neccesary!!!
### Check if path for archiving GRASS mapsets is correct and create it if neccesary!!!

location="/data/grassdata/Norge_ETRS_32N"
mapset="ninsbl_viewshed_VIEWSHED"

#########################################################################
# defining input variables 
#########################################################################

# Load map containing boundaries of house polygons to process into GRASS
house_boundaries=$(v.extract input="PG:dbasename=gisdata" layer="openness.houses" output="house_polygons" where="")

# Extract midtpoints of polygon boundaries
v.to.points -i --overwrite --verbose input=house_boundaries type=line output=house_boundary_points

# DSM for Oslo
dsm=dsm@Openness

# path and file name of viewshed output in vector form SQLite DB 
output_vectors="/Prosjekter/OpenNess/GIS/viewshed_grass/viewshed_VIEWSHED.sqlite"

#########################################################################
# start processing
#########################################################################

# Extract attributes (gid, x and y) of the observer points at the outside of the houses
observer_points=$(v.db.select -c map=house_boundary_points columns=gid,x,y where="a_cat=$w" separator=comma | sort -n | uniq)

# Loop over points at the outside of the houses
for p in $observer_points
do

# Load attributes int variables
gid=$(echo $p | cut -d',' ' -f1)
x=$(echo $p | cut -d',' ' -f2)
y=$(echo $p | cut -d',' ' -f3)

# Set region to an area 10km around input houses
g.region -p n=$y s=$y w=$x e=$x align=$dsm
g.region -p n=n+10000 s=s-10000 w=w-10000 e=e+10000 align=$dsm

# Run viewshed analysis
r.viewshed -c -b --overwrite --verbose input=$dsm output=viewshed_${gid} coordinates="${x},${y}" memory=10000
	
# Convert viewshed map from raster to vector
r.to.vect input=viewshed_${gid} output=viewshed_${gid} type=area --q --o

# Add empty attribute tabel to viewshed polyon
v.db.addtable map=viewshed_${gid} columns="gid integer"
	
# Populate new columns with values
v.db.update map=viewshed_${gid} layer=1 column=gid value=${gid}

# Store watershed vectors to sqlite db file
if [ ! -f "$output_vectors" ] ; then
# Create SQLite DB if it does not exist
v.out.ogr format="SQLite" olayer=openness_viewsheds input=viewshed_${gid} type=area dsn="$output_vectors"
else
# Append to SQLite DB if it exists
v.out.ogr -ua format="SQLite" olayer=openness_viewsheds input=viewshed_${gid} type=area dsn="$output_vectors"
fi

# Remove temporary files
g.remove --q rast=viewshed_${gid}

# End loop
done

mv ${location}/${mapset} /Prosjekter/OpenNess/GIS/viewshed_grass/mapsets/${mapset}
