# WRF preprocessing (WPS) toolkit using IMDAA initial conditions and lateral boundary forcing

The purpose of this shell script is to run the WPS program with IMDAA data to produce metgrid output files at user-defined intervals. This generates separate intermediate files (by UNGRIB) for different parameters such as mean sea level pressure, skin temperature, 2-meter Relative humidity, 2-meter temperature, etc. Next is GEOGRID, which turns all static data into user-defined grid points. Then there is METGRID, which takes the GEOGRID output and uses these different parameters (in UNGRIB format) as intermediate data. The script follows GRIB2 parameter identities for the NCMRWF Unified Model (NCUM) output conventions; therefore, the "tables" folder consists of some essential tables that need to be downloaded along with this script. After successful completion of this script, the user should conventionally proceed with REAL.EXE and WRF.EXE (or TC.EXE and NDOWN.EXE).

# This script performs three jobs:
1. Run geogrid.exe
2. Run ungrib.exe for all parameters separately
3. Run metgrid.exe

# PREREQUISITES
1. WRF pre-processing program (i.e., WPS). This path needs to be given in the user_input file (as "wps_path").
2. wgrib2 and eccodes for sorting the data.
3. NETCDF4 and NCKS for checking data.
4. Openmpi, mpich, Intel C, or Intel Fortran for parallel runs. Otherwise, go for a serial run.
5. Download IMDAA data and keep all files (single- and pressure-level data) in one directory. Give this directory path as "imdaa_data_path" in the user input section. Do not keep single and pressure-level data separately in different directories.
7. The user must have a namelist.wps in order to run this script. Give the full path in the user_input.sh (preferably keep namelist.wps in a different location so that it stays unchanged).

# How to use:
1. Download IMDAA data and keep all files (single and pressure-level data) in one directory. Give this directory path as "imdaa_data_path" in the user_input file. Do not keep single and pressure-level data separately in different directories.
2. Create a folder in your preferred location and keep this repository. Nothing else needs to be kept in this directory. or just clone the repository.
3. Fill all the details in the user_input.sh file
4. keep the "tables" folder as it is
5. Make the script executable:

		chmod +x runscript_ncmrwf.sh
   
8. Then type:

		 ./runscript_ncmrwf.sh
