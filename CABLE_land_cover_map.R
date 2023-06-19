library(raster)
library(ncdf4)


#Using this gridinfo file as the starting point:
#/g/data/w97/mm3972/model/cable/src/CABLE-AUX/offline/mmy_gridinfo_AU/gridinfo_AWAP_OpenLandMap_ELEV_DLCM_fix.nc
#First delete iveg using CDO 
#cdo delvar,iveg gridinfo_AWAP_OpenLandMap_ELEV_DLCM_fix.nc gridinfo_new_iveg.nc
#Then add new iveg file using this code


path <- "/g/data/w97/Shared_data/"


### Read dynamic land cover dataset v2.1 ###

#Use 2002-2003 land cover

lc <- raster(paste0(path, "/Land_cover_maps/Dynamic_land_cover_dataset/v2.1/",
                    "DLCD_v2-1_MODIS_EVI_1_20020101-20031231.tif"))


### Reclassify data ###

#Resample to AWAP resolution
awap <- raster(paste0(path, "/../mm3972/model/cable/src/CABLE-AUX/offline/",
                      "mmy_gridinfo_AU/gridinfo_AWAP_OpenLandMap_ELEV_DLCM_fix.nc"),
               varname="iveg")

lc_resampled <- resample(lc, awap, method="ngb")


### CABLE classes ###

#DLCD values corresponding to CABLE PFTs

#Make sparse and scattered trees and shrubs grass

# dlcd_veg <- list(urban = c(1,35), #urban
#                   lake = c(3,4), #lake
#                   c3_crop=c(5,8,6,9,7,10), #C3 crop
#                   wetlands=11, #wetland
#                   grassland=c(16,14,15, 18,19,34,33), #C3 or C4 grass
#                   shrub=c(24,25),
#                   ebf=c(31,32))

dlcd_veg <- list(urban = c(1,35), #urban
                  lake = c(3,4), #lake
                  c3_crop=c(5,8,6,9,7,10), #C3 crop
                  wetlands=11, #wetland
                  grassland=c(16,14,15, 18,19,33), #C3 or C4 grass
                  shrub=c(24,25,34),
                  ebf=c(31,32))


cable_veg <- list(urban = 15, #urban
                 lake = 16, #lake
                 c3_crop=9, #C3 crop
                 wetlands=11, #wetland
                 grassland=6, #C3 for now, adjust for C4 below
                 shrub=5,
                 ebf=2)

#Initialise
iveg <- lc_resampled

#veg types
names = names(dlcd_veg)

#Loop through veg types
for(k in names) {
  
  iveg[lc_resampled %in% unlist(dlcd_veg[k])] <- unlist(cable_veg[k])
  
}


### Fix C4 fraction ###

#Read C4 fraction data
c4 <- raster(paste0(path, "/Land_cover_maps/C4_fraction/Proprotional_C4_vegation.tif"))

c4_resampled <- resample(c4, iveg)

#Set grass pixels where C4 fraction >= 0.5 to C4 grass
iveg[iveg == 6 & c4_resampled >=0.5] <- 7


### Plotting ###

#Plot as a sanity check

par(mfcol=c(1,1))
# plot(iveg)

col <- c("darkgreen", "#d8b365", "lightgreen", "pink", "purple", "turquoise", "grey", "darkblue")

breaks <- c(1, 2.5, 5.5, 6.5, 7.5, 9.5, 11.5,  15.5, 16.5)

plot(iveg, breaks=breaks, col=col)

legend("bottomleft", legend=c("EBF", "shrub", "C3 grass", "C4 grass", "C3 crop", "wetland", "urban", "lake"),
       fill=col, cex=0.8, bty="n")

#EBF, shrub, C3 grass, C3 crop, wetland, urban, lake
#2 16  6 11 15  9  5

 # plot(awap, breaks=breaks, col=col)
  

  
### Write to file ###  

nc <- nc_open(paste0(path, "/../amu561/VPD_drought_impacts/CABLE_inputs/gridinfo_new_iveg.nc"), write=TRUE)

iveg_var <- ncvar_def("iveg", units="-", dim=list(nc$dim$longitude, nc$dim$latitude), prec="integer")

nc <- ncvar_add(nc, iveg_var)

ncvar_put(nc, varid=iveg_var, vals=aperm(as.array(flip(iveg, direction='y'))))#, c(2,1,3))) 
nc_close(nc)

  
  