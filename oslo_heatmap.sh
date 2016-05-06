#############################################################################
# AUTHOR(S): Stefan Blumentrath
# PURPOSE: Estimate Land Surface Temperature (LST)
# COPYRIGHT: (C) 2016 by the Stefan Blumentrath
#
# This script estimates Land Surface Temperature (LST) in Oslo 
# during the warmest periode in summer
#
# This program is free software under the GNU General Public
# License (>=v2). Read the file COPYING that comes with GRASS
# for details.
#############################################################################

# Landsat scene chosen to represent a summer heat wave
# see: https://www.yr.no/sted/Norge/Oslo/Oslo/Oslo_%28Blindern%29_m%C3%A5lestasjon/statistikk.html
# DOY 183 in 2015 is start of the periode with the warmest day in 2015 

mkdir LC81980182015183LGN00
cd LC81980182015183LGN00
landsat download LC81980182015183LGN00
tar -xvzf LC81980182015183LGN00.tar.gz
for input_band_name in $(ls *.TIF)
do
# Extract meta information
ouput_band_name=$(echo $input_band_name | sed 's/\.TIF$//g')
band=$(echo $input_band_name | cut -f2 -d '_' | cut -f1 -d '.' | sed 's/B//g')
path=$(echo $input_band_name | cut -c "4-6")
row=$(echo $input_band_name | cut -c "7-9")
year=$(echo $input_band_name | cut -c "10-13")
doy=$(echo $input_band_name | cut -c "14-16")
date=$(date -d "01/01/${year} +${doy} days -1 day")

# Import to GRASS
# Note that r.external would avoid duplicated data
# and that r.import would allow for reprojection to other CRS (than UTM 32N in this case)
r.in.gdal -o input=$input_band_name output=$ouput_band_name memory=2047 title="Band ${band} of Landsat8 scene from ${date}, path ${path}, row ${row}" --overwrite --verbose
done

# Download land cover map for the scene
# Should be replaced by a propper land cover map
wget http://data.ess.tsinghua.edu.cn/data/FROM_GLC_agg/198/L5198018_01820100704_Rad_Ref_TRC_BYTE-FROMGLCaggV1.tar.gz
# Import downloaded land cover map for the scene
r.in.gdal -o input=L5198018_01820100704_Rad_Ref_TRC_BYTE-FROMGLCaggV1.tif output=L5198018_01820100704_Rad_Ref_TRC_BYTE_FROMGLCaggV1 memory=2047 title="Higher resolution land cover from http://data.ess.tsinghua.edu.cn/data/FROM_GLC_agg/198/" --overwrite --verbose

g.region -p raster=LC81980182015183LGN00_B1 align=LC81980182015183LGN00_B1

# Estimate LST with land cover adjustments 
i.landsat8.swlst -c --overwrite --verbose mtl="${HOME}/Prosjekter/OpenNESS/Satellite imagery/LC81980182015183LGN00_MTL.txt" prefix=LC81980182015183LGN00_B lst=LC81980182015183LGN00_LST landcover=L5198018_01820100704_Rad_Ref_TRC_BYTE_FROMGLCaggV1

# Generate map with average emmissivity which can be used as a artificial constant (control for land cover adjustments) 
r.mapcalc --o expression="GLC=70"
i.landsat8.swlst -c --overwrite --verbose mtl="${HOME}/Prosjekter/OpenNESS/Satellite imagery/LC81980182015183LGN00_MTL.txt" prefix=LC81980182015183LGN00_B lst=LC81980182015183LGN00_LST_const_LC landcover=GLC #emissivity=emmisivity

# Export to non-GRASS / non-NINSRV16 users:
r.out.gdal input=LC81980182015183LGN00_LST output="${HOME}/Prosjekter/OpenNESS/Satellite imagery/LC81980182015183LGN00_LST.tif" createopt="TFW=YES,COPMRESS=LZW,PREDICTOR=3"
r.out.gdal input=LC81980182015183LGN00_LST_const_LC output="${HOME}/Prosjekter/OpenNESS/Satellite imagery/LC81980182015183LGN00_LST_const_LC.tif" createopt="TFW=YES,COPMRESS=LZW,PREDICTOR=3"
