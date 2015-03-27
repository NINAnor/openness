# grønntplan Mangelanalyse

for f in $(ls /home/stefan/R_Prosjekter/OpenNESS/GIS/Variabler_Nora/*.shp)
do
	map=$(basename $f | sed 's/....$//g')
	v.in.ogr dsn=$f output=$map -ow encoding=LATIN4
done
v.in.ogr -o -w dsn="PG:dbname=gisdata" layer="openness.utm_32n_adresse_housing_units_oslo" output="openness_utm_32n_adresse_housing_units_oslo" min_area=0.0001 snap=-1

#g.region
g.region -p vect=openness_utm_32n_adresse_housing_units_oslo,Parker align=hoh@Policymix n=n+1000 s=s-1000 w=w-1000 e=e+1000

v.proj input=N50_2013_arealdekke_pol location=ninsbl_Norge_WGS84_33N mapset=Oekokart

v.to.rast input=Parker output=park_small where="areal>= 1000 AND areal<=5000" use=val value=1 --o
v.to.rast input=Parker output=park_medium where="areal>5000 AND areal <= 100000" use=val value=10 --o
v.to.rast input=Parker output=park_large where="areal>100000" use=val value=100 --o
v.to.rast input=markagrensa output=markagrensa use=val value=1 --o
v.to.rast input=Bydeler_samlet output=Bydeler_samlet use=val value=1 --o
v.to.rast input=Parker output=parker where="areal>1000" use=cat --o

r.grow.distance input=park_small dist=park_small_dist --o
r.grow.distance input=park_medium dist=park_medium_dist --o
r.grow.distance input=park_large dist=park_large_dist --o
r.grow.distance input=markagrensa dist=marka_dist --o

psql -d gisdata -c "COPY(SELECT ST_X(geom), ST_Y(geom), 1 FROM openness.utm_32n_adresse_housing_units_oslo) TO STDOUT WITH CSV" -q | r.in.xyz input=- output=housing_units_oslo method=n separator=',' --o
r.mapcalc expression="park_small_250m=if(park_small_dist<=250,1,null())" --o
r.mapcalc expression="park_medium_500m=if(park_medium_dist<=500,10,null())" --o
r.mapcalc expression="park_large_1000m=if(park_large_dist<=1000,100,null())" --o
r.mapcalc expression="marka_1000m=if(marka_dist<=1000,1000,null())" --o
r.mapcalc expression="park_coverage_oslo=park_small_250m+park_medium_500m+park_large_1000m+n50_skog_oslo_1000m" --o
r.mapcalc expression="park_coverage_oslo=if(isnull(park_small_250m),0,1)+if(isnull(park_medium_500m),0,10)+if(isnull(park_large_1000m),0,100)+if(isnull(marka_1000m),0,1000)" --o

r.stats -n --verbose input=park_coverage_oslo@ninsbl_OpenNESS,parker@ninsbl_OpenNESS | cut -f1 -d' ' | sort -n | uniq -c
r.mask raster=parker
r.stats -1n --verbose input=park_coverage_oslo@ninsbl_OpenNESS | sort -n | uniq -c
r.mask -r

v.to.rast input=N50_2013_arealdekke_pol output=residental_areas where="(objtype='BymessigBebyggelse' OR objtype='TettBebyggelse' OR objtype='Industriområde' OR objtype='ÅpentOmråde') AND kommune = 301" use=val value=1 --o
r.mapcalc expression=residental_areas_oslo=if(Bydeler_samlet,residental_areas,null())
r.mask raster=residental_areas_oslo

r.stats.zonal --overwrite --verbose base=park_coverage_oslo cover=housing_units_oslo method=sum output=park_coverage_housing_units_oslo


r.univar -t --overwrite --verbose map=housing_units_oslo@ninsbl_OpenNESS zones=park_coverage_oslo@ninsbl_OpenNESS output=/data/home/stefan/Avd15GIS/GAMMELT/Stefan/opennes_park_coverage.csv separator=comma

r.mask -r
v.to.rast input=openness_utm_32n_adresse_housing_units_oslo output=postnr_pre use=attr attrcolumn=postnr --o
r.grow.distance input=postnr_pre value=postnr --o
r.to.vect -s input=postnr output=postnr type=area column=postbr --o
g.remove rast=postnr_pre
