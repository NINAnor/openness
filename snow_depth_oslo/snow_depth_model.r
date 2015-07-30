### This script aims at predicting the likelihood of > 10cm snow cover and average snow depth
### based on the altitudes in the greater Oslo area 
### as an indicator for the skiing conditions in the average of the years 1981 to 2009
###
###This R-script has to be started from within a GRASS session

#Load required libraries
library("rgrass7")

#Define terrain model to use for analysis
DEM <- "DEM_10m_Oslo"

#Load data on snow statistics
snow_observ_total <- read.csv("/home/stefan/R_Prosjekter/OpenNESS/GIS/Snow_depth/snow_depth_probability_81_2010_senorge.csv", header=TRUE, sep=',')

#Set analysis region to DEM
execGRASS("g.region", flags=c("p"), raster=DEM)

for (m in 1:12) {
	
	print(paste("Analysing month: ", m, sep=''))
	#Extract snow statistics by month
	snow_observ_month <- snow_observ_total[grep(TRUE, snow_observ_total$month == m),]
	
	#Check if snow is present within the given month
	if( max(snow_observ_month$depth) > 0 & max(snow_observ_month$probability) > 0) {
		
		#Extract days from snow statistic data sets
		days <- unique(sort(paste(snow_observ_month$month, snow_observ_month$day,sep="_")))

		#Make a snow depth map per day
		for (d in days) {
			#Extract snow statistics by day
			snow_observ_day <- snow_observ_month[grep(TRUE, snow_observ_month$day == strsplit(d, '_')[[1]][2] & snow_observ_month$month == m),]
			
			#Check if snow is present at given date
			if( max(snow_observ_day$depth > 0 & max(snow_observ_day$probability) > 0)) {
				##Create a snow depth model
				#snow_mod <- glm(depth ~ altitude, data = snow_observ_day)
				#Create a snow probability model
				snow_prob <- glm(probability ~ log(altitude), data = snow_observ_day)
				##Predict snow depth for DEM
				#execGRASS("r.mapcalc", flags=c("overwrite"), expression=paste("oslo_snow_depth_", d, " = ", snow_mod$coefficients[1], " + ", snow_mod$coefficients[2], " * ", DEM, sep=''))
				#Predict snow probability for DEM
				execGRASS("r.mapcalc", flags=c("overwrite"), expression=paste("oslo_snow_greater_10cm_probability_", d, " = ", snow_prob$coefficients[1], " + ", snow_prob$coefficients[2], " * log( ", DEM, " )", sep=''))
				execGRASS("r.mapcalc", flags=c("overwrite"), expression=paste("oslo_snow_greater_10cm_probability_bin_", d, " = if(oslo_snow_greater_10cm_probability_", d, " >= 0.33, 1 , 0)", sep=''))  
			} else
			{
				#execGRASS("r.mapcalc", flags=c("overwrite"), expression=paste("oslo_snow_depth_", d, " = 0", sep=''))
				#execGRASS("r.mapcalc", flags=c("overwrite"), expression=paste("oslo_snow_greater_10cm_probability_", d, " = 0", sep=''))
			}
		}
		##Aggregate snow statistics by month
		#snow_depth_maps <- execGRASS("g.list", type="raster", pattern=paste("oslo_snow_depth_", m, "_*", sep=''), separator="comma", legacyExec=TRUE, redirect=TRUE)
		#snow_probability_maps <- execGRASS("g.list", type="raster", pattern=paste("oslo_snow_greater_10cm_probability_", m, "_*", sep=''), separator="comma", legacyExec=TRUE, redirect=TRUE)
		#execGRASS("r.series", 
		#execGRASS("r.out.gdal",
	}
}
snow_probability_maps <- execGRASS("g.list", type="raster", pattern=paste("oslo_snow_greater_10cm_probability_bin_*", sep=''), separator="comma", legacyExec=TRUE, redirect=TRUE)
execGRASS("r.series", flags=c("overwrite"), input= paste(c(snow_probability_maps), collapse=""), output="oslo_snow_days_greater_10cm_0_33_prob", method="sum")
execGRASS("r.out.gdal", input="oslo_snow_days_greater_10cm_0_33_prob", output="/home/stefan/oslo_snow_days_greater_10cm_0_33_prob.tif", format="GTiff", createopt="COMPRESS=LZW,TFW=YES")
