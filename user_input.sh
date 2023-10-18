#!/bin/bash
#----------------------------------------------------------------------------------------------------------------------------------------
#                                                                                                                                       |
#                       (A) Provide only relevant paths in the path options.                                                            |
#                       (B) Provide the number of processors if opting for parallel.                                                    |
#                       (C) Set false if you do not want to repeat the process.		                                                |
#                       (D) Download the essential data only as below from the IMDAA portal:						|
#                                                                                                                                       |
#                   		 1. U component wind in pressure level (IMDAA DATA NAME: UGRD-prl)					|
#		                 2. V component wind in pressure level (IMDAA DATA NAME: VGRD-prl)					|
#		                 3. Temperature in pressure level (IMDAA DATA NAME: TMP-prl)						|
#		                 4. Surface temperature (IMDAA DATA NAME: TMP-sfc)							|
#		                 5. Geopotential height in pressure level (IMDAA DATA NAME: HGT-prl)					|
#                		 6. Relative humidity in pressure level (IMDAA DATA NAME: RH-prl)					|
#		                 7. 2-meter Relative humidity (IMDAA DATA NAME: RH-2m)							|
#		                 8. Land mask file (IMDAA DATA NAME: LAND-sfc)								|
#		                 9. Surface pressure (IMDAA DATA NAME: PRES-sfc)							|
#		                10. Mean sea level pressure (IMDAA DATA NAME: PRMSL-msl)						|
#		                11. Soil temperature level 1 (IMDAA DATA NAME: TSOIL-L1)						|
#		                12. Soil temperature level 2 (IMDAA DATA NAME: TSOIL-L2)						|
#		                13. Soil temperature level 3 (IMDAA DATA NAME: TSOIL-L3)						|
#		                14. Soil temperature level 4 (IMDAA DATA NAME: TSOIL-L4)						|
#		                15. 10-meter U wind (IMDAA DATA NAME: UGRD-10m)								|
#		                16. 10-meter V wind (IMDAA DATA NAME: VGRD-10m)								|
#		                17. Soil moisture level 1 (IMDAA DATA NAME: CISOILM-L1)							|
#		                18. Soil moisture level 2 (IMDAA DATA NAME: CISOILM-L2)							|
#		                19. Soil moisture level 3 (IMDAA DATA NAME: CISOILM-L3)							|
#		                20. Soil moisture level 4 (IMDAA DATA NAME: CISOILM-L4)							|
#				21. Water equivalent accumulated snow depth (IMDAA DATA NAME: WEASD-sfc)				|
#                                                                                                                                       |
#----------------------------------------------------------------------------------------------------------------------------------------
#                                                                                                                                       |
#                             [ Please see the sample_user_input file to get an idea ]                                                  |
#                                           USER INPUT BEGIN HERE                                                        		|
#                                                                                                                                       |
#----------------------------------------------------------------------------------------------------------------------------------------

# Path where you kept all downloaded IMDAA data together
imdaa_data_path=path_to_downloaded_imdaa_data_directory

# This is the path where you have installed the WPS package
wps_path=path_to_installed_WPS_directory

# Static data WPS_GEOG path
wps_geog_path=path_to_WPS_GEOG_static_data_directory

# Put your namelist.wps in this path
wps_namelist=full_path_of_namelist.wps

# number of processors if opting for parallel run
nproc=1

# set false if you do not want to repeat the processes from the start
SORT_IMDAA=true
RUN_GEOGRID=true
RUN_UNGRIB=true

#----------------------------------------------------------------------------------------------------------------------------------------
#                                                                                                                                       |
#	       		                  	END USER INPUT				                                        	|
#                                                                                                                                       |
#----------------------------------------------------------------------------------------------------------------------------------------
