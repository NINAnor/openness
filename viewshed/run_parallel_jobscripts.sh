#############################################################################
# AUTHOR(S): Stefan Blumentrath
# PURPOSE: Calculate viewsheds for houses in Oslo
# COPYRIGHT: (C) 2015 by the Stefan Blumentrath
#
# This script generates jobscripts for GRASS GIS batch jobs from viewshed_jobscript_template.sh
# and executes them in parallel using xargs
#
# This program is free software under the GNU General Public
# License (>=v2). Read the file COPYING that comes with GRASS
# for details.
#############################################################################
#
###########
### To Do:
### Check if envireonment variables and lined up commands work in xargs
### Alternative: start the single jobscripts manually 

location="/data/grassdata/Norge_ETRS_32N"
mapset="ninsbl_viewshed_"

CORES=10

for c in seq 1 $CORES
do

# Create empty GRASS mapset to run the script in
if [ ! -d "${location}/${mapset}" ] ; then
	grass70 -ce "${location}/${mapset}_${c}"
fi

# Create job scripts
cat jobscript_template.sh | sed 's/VIEWSHED/$c/g' > calculate_viewsheds_${c}.sh

# Make jobscript executable
chmod ugo+x calculate_viewsheds_${c}.sh

done

# Execute job sripts in parallel using xargs
seq 1 $CORES | awk '{print "export GRASS_BATCH_JOB=\"calculate_viewsheds_" $1 "; grass70 \"${location}/${mapset}_" $1 "\"; unset GRASS_BATCH_JOB\0"}' | xargs -0 -P $CORES -I {} bash -c {}
