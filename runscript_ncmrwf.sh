#!/bin/bash
#------------------------------------------------------------------------------------------------------------------------
# The purpose of this script is to produce metgrid output files in user-defined intervals from IMDAA data. 		|
#															|
# This generates separate intermediate files (by UNGRIB) for different parameters such as mean sea level 		|
# pressure, 2-meter  Relative humidity, 2-meter temperature, etc. Thereafter METGRID is performed by taking these 	|
# different parameters together along with GEOGRID grid information. The script follows GRIB2 parameter identities 	|
# for the NCMRWF Unified Model (NCUM) output conventions only. To satisfy this, user must download the 'tables' folder 	|
# along with this repository. After successful completion of this script, the user should proceed for REAL.EXE and 	|
# WRF.EXE in the conventional way.											|	
#															|
# This script performs 3 jobs only:											|
#															|
# 1. Run geogrid.exe													|
# 2. Run ungrib.exe for all parameters separately									|
# 3. Run metgrid.exe 													|
#															|
#----------------------------------------------	   CONTACTS	--------------------------------------------------------|
#															|
# Team: V. Hazra, Gibies George, Syam Sankar, S. Indira Rani, Mohan S. Thota, John P. George, Sumit Kumar, 		|
#	Laxmikant Dhage													|
# National Centre for Medium-Range Weather Forecasting, ESSO, Ministry of Earth Sciences, Govt. of India		|
# Contact if any issue arises while running this script: vhazra@ncmrwf.gov.in						|
# Copyright @ NCMRWF, MoES, 2023											|
#															|
#-------------------------------------------	PREREQUISITES	--------------------------------------------------------|
# PREREQUISITES:													|
# (1) Installed WPS. The path needs to be given in wps_path.								|
# (2) Installed wgrib2 for sorting the data.										|
# (3) Installed NETCDF4 for checking data.										|
# (4) Installed openmpi or mpich for parallel run. Otherwise, go for a serial run.					|
# (5) Download the IMDAA data. Keep it as it is and mention the path in imdaa_data_path.				|
# (6) The essential variables to run the WRF are: 									|
#						U component wind in pressure level (IMDAA DATA NAME: 	UGRD-prl)	|
#						V component wind in pressure level (IMDAA DATA NAME: 	VGRD-prl)	|
#						Temperature in pressure level (IMDAA DATA NAME: 	TMP-prl)	|
#						Surface temperature (IMDAA DATA NAME: 			TMP-sfc)	|
#						Geopotential height in pressure level (IMDAA DATA NAME: HGT-prl)	|
#						Relative humidity in pressure level (IMDAA DATA NAME: 	RH-prl)		|
#						2-meter Relative humidity (IMDAA DATA NAME: 		RH-2m)		|
#						Land mask file (IMDAA DATA NAME: 			LAND-sfc)	|
#						Surface pressure (IMDAA DATA NAME: 			PRES-sfc)	|
#						Mean sea level pressure (IMDAA DATA NAME: 		PRMSL-msl)	|
#						Soil temperature level 1 (IMDAA DATA NAME: 		TSOIL-L1)	|
#						Soil temperature level 2 (IMDAA DATA NAME: 		TSOIL-L2)	|
#						Soil temperature level 3 (IMDAA DATA NAME: 		TSOIL-L3)	|
#						Soil temperature level 4 (IMDAA DATA NAME: 		TSOIL-L4)	|
#						10-meter U wind (IMDAA DATA NAME: 			UGRD-10m) 	|
#						10-meter V wind (IMDAA DATA NAME: 			VGRD-10m)	|
#						Soil moisture level 1 (IMDAA DATA NAME: 		CISOILM-L1)	|
#						Soil moisture level 2 (IMDAA DATA NAME: 		CISOILM-L2)	|
#						Soil moisture level 3 (IMDAA DATA NAME: 		CISOILM-L3)	|		
#						Soil moisture level 4 (IMDAA DATA NAME: 		CISOILM-L4)	|
#						Water equivalent accumul. snow depth (IMDAA DATA NAME: 	WEASD-sfc)	|
#															|
#------------------------------------------------ USEAGE ---------------------------------------------------------------|
# USAGE:														|
#															|
# (1) Create a folder in your preferred location and keep this repository. Nothing else needs to be kept in this 	|
#     directory.													|
# (2) Give the path (in the user_input.sh) where you have kept namelist.wps (preferably in a different 			|
#     location).													|
# (3) Download IMDAA data and keep all (single level and pressure level) in one directory. Then give this		|	 
#     directory path in	"imdaa_data_path" in the user_input.sh.								|
# (4) Provide all essential paths as required in user_input.sh								|
# (5) Provide the number of processors in user_input.sh if opting for parallel run 					|
# (6) Keep the "tables" folder in this directory 									|
# (7) chmod +x runscript_ncmrwf.sh 											|
# (8) ./runscript_ncmrwf.sh												|
# (9) After successful completion, go for real.exe and wrf.exe								|
#															|
#------------------------------------------ USEFUL INFORMATIONS --------------------------------------------------------|
#															|
# Set relevant paths and data information in the user_input.sh								|
# This script assumes you have installed wgrib2, netcdf4, openmpi or mpich (if parallel), and the WPS program 		|
# prior to running this script.												|
#															|
# Author : Vivekananda Hazra (vhazra@ncmrwf.gov.in)									|
# Version : 30-Sep-2023													|
#------------------------------------------------------------------------------------------------------------------------

set -x
currdir=`pwd`
ulimit -s unlimited
BLUE='\033[0;34m'
NC='\e[0m'
RED='\033[0;31m'
BRed='\033[1;31m'
BGreen='\033[1;32m'
rm -rf .success .unsuccess GRIBFILE* METGRID.TBL Vtable GEOGRID.TBL met_em.* namelist.wps namelist.wps.original

nml=${currdir}/user_input.sh
if [ -f "$nml" ]; then
	echo -e "\n
        ${BGreen}user_input.sh${NC} exists.

        Proceeding ...
        \n"
        sleep 0.5
	chmod +x user_input.sh
	source user_input.sh
else
	echo  -e "\n ${BRed}
        \n
        \n
        \n
        \n
        \n
        \n
                      user_input.sh does not exist in this specified path: $currdir ${NC}
                      ---------------------------------------------------

        ${BGreen}
        Solutions${NC}:

	1. Please make sure the downloaded "user_input.sh" file exists here.
	2. Fill it correctly and then re-run this script.

        ${BRed}
	Exiting ...${NC}
	\n"
	exit 1
fi

# Checking the user_input.sh
if [ -z "$imdaa_data_path" ]; then
        echo -e "\n
	\n
	\n
	\n
	\n
	\n
	\n
        ${BRed}
                                The variable name 'imdaa_data_path' has been changed in the user_input.sh file${NC}
                                ------------------------------------------------------------------------------
        ${BGreen}
                                Solution${NC}:\n
				Please do not change the 'imdaa_data_path' to another name in the user_input.sh file.
                                Just fill in the required details and re-run this script.\n 
				DO NOT MAKE ANY CHANGES APART FROM JUST FILLING.
        \n"
        exit 1
else
        if [ -z "$wps_path" ]; then
                echo -e "\n
	\n
	\n
	\n
	\n
	\n
	\n
                ${BRed}
                                The variable name 'wps_path' has been changed in the user_input.sh file${NC}
                                -----------------------------------------------------------------------
                ${BGreen}
                                Solution${NC}:\n
				Please do not change the 'wps_path' to another name in the user_input.sh file.
                                Just fill in the required details and re-run this script.\n
				DO NOT MAKE ANY CHANGES APART FROM JUST FILLING.
                \n"
                exit 1
        else
                if [ -z "$wps_geog_path" ]; then
                        echo -e "\n
	\n
	\n
	\n
	\n
	\n
	\n
                        ${BRed}
                                The variable name 'wps_geog_path' has been changed in the user_input.sh file${NC}
                                ----------------------------------------------------------------------------
                        ${BGreen}
                                Solution${NC}:\n
				Please do not change the 'wps_geog_path' to another name in the user_input.sh file.
                                Just fill in the required details and re-run this script.\n
				DO NOT MAKE ANY CHANGES APART FROM JUST FILLING.
                        \n"
                        exit 1
                else
                        if [ -z "$wps_namelist" ]; then
                                echo -e "\n
	\n
	\n
	\n
	\n
	\n
	\n
                                ${BRed}
                                The variable name 'wps_namelist' has been changed in the user_input.sh file${NC}
                                ---------------------------------------------------------------------------
                                ${BGreen}
                                Solution${NC}:\n
				Please do not change the 'wps_namelist' to another name in the user_input.sh file.
                                Just fill in the required details and re-run this script.\n
				DO NOT MAKE ANY CHANGES APART FROM JUST FILLING.
                                \n"
                                exit 1
			else
				if [ -z "$nproc" ]; then
					echo -e "\n
				        \n
				        \n
				        \n
				        \n
				        \n
				        \n
	                                ${BRed}
                                The variable name 'nproc' has been changed in the user_input.sh file${NC}
                                ---------------------------------------------------------------------------
        	                        ${BGreen}
                                Solution${NC}:\n
                                Please do not change the 'nproc' to another name in the user_input.sh file.
                                Just fill in the required details and re-run this script.\n
                                DO NOT MAKE ANY CHANGES APART FROM JUST FILLING.
                                \n"
                                exit 1
				fi
                        fi
                fi
        fi
fi

# Checking for user entries
if [[ "$SORT_IMDAA" == "true" ]]; then
    echo "Proceeding ..."
elif [[ "$SORT_IMDAA" == "false" ]]; then
    echo "Proceeding ..."
else
    echo -e "\n
    \n
    \n
    \n
    \n
    \n
    \n
    ${BRed}
				    Invalid Input
				    -------------\n
    Set either true or false in user_input.sh file. No other entries would be accepted.
    ${NC}

    Example:

	SORT_IMDAA=${BRed}true${NC}
	
	or

	SORT_IMDAA=${BRed}false${NC}
    
    Exiting...
    \n"
    exit 1
fi
if [[ "$RUN_GEOGRID" == "true" ]]; then
    echo "Proceeding ..."
elif [[ "$RUN_GEOGRID" == "false" ]]; then
    echo "Proceeding ..."
else
    echo -e "\n
    \n
    \n
    \n
    \n
    \n
    \n
    ${BRed}
    				Invalid Input
				-------------\n
    Set either true or false in user_input.sh file. No other entries would be accepted.
    ${NC}

    Example:

        RUN_GEOGRID=${BRed}true${NC} 
	
	or 
	
	RUN_GEOGRID=${BRed}false${NC}

    Exiting...
    \n"
    exit 1
fi
if [[ "$RUN_UNGRIB" == "true" ]]; then
    echo "Proceeding ..."
elif [[ "$RUN_UNGRIB" == "false" ]]; then
    echo "Proceeding ..."
else
    echo -e "\n
    \n
    \n
    \n
    \n
    \n
    \n
    ${BRed}
    				Invalid Input
				-------------\n
    Set either true or false in user_input.sh file. No other entries would be accepted.
    ${NC}

    Example:

        RUN_UNGRIB=${BRed}true${NC}
	
	or
	
	RUN_UNGRIB=${BRed}false${NC}

    Exiting...
    \n"
    exit 1
fi

# checking for the existence of the "tables" folder
if [ ! -d tables ]
then
    echo -e "\n
    \n
    \n
    \n
    \n
   		 The tables directory does not exist
		 -----------------------------------
   
    ${BRed}Exiting ...${NC}
    \n"
    echo  -e "\n
    \n
    ${BRed}tables directory does not exist in this path:${NC}
    Please keep all downloaded repositories here. Then re-run the script.
    ---------------------------------------------------------------------
    \n"
    exit 1
else
	file1=$currdir/tables/METGRID.TBL_NCUM2
	file2=$currdir/tables/Vtable.NCUM2
	file3=$currdir/tables/ncmr_grib2_local_table2
	if [ -f "$file1" ] && [ -f "$file2" ] && [ -f "$file3" ]; then
		echo -e "\n
                ${BGreen}METGRID.TBL_NCUM2${NC}, ${BGreen}Vtable.NCUM2${NC}, and ${BGreen}ncmr_grib2_local_table2${NC} exist.

                Proceeding ...
                \n"
                sleep 0.5
		cp -rf $currdir/tables/METGRID.TBL_NCUM2 METGRID.TBL
		cp -rf $currdir/tables/Vtable.NCUM2 Vtable
		export GRIB2TABLE=$currdir/tables/ncmr_grib2_local_table2
	else
                echo -e "\n tables folder exists. But one or more of the required files are missing"
                echo  -e "\n ${BRed}
                \n
                \n
                \n
                			Some files do not exist in this specified path:${NC}
					----------------------------------------------

                ${BGreen}
		Solutions${NC}:

                Please make sure the downloaded "tables" repository exists here (which comprises METGRID.TBL_NCUM2, Vtable.NCUM2, and ncmr_grib2_local_table2).
                Then re-run the script.

                ${BRed}Exiting ...${NC}
                \n"
                exit 1
        fi
fi
# checking for the existence of Namelist
FILE=$wps_namelist
if [ ! -f $FILE ]
then
    echo -e "\n ${BRed}namelist.wps does not exist.${NC} \n"

    echo  -e "\n
    \n
    \n
    \n
    \n

			    namelist.wps does not exist in the specified folder

    ${BGreen}
    Solutions${NC}:

    Please provide the correct path of the namelist.wps as described by the sample script. Then re-run the script.
    -------------------------------------------------------------------------------------------------------------
    \n"
    exit 1
fi
#------------------------------------------------------------------------------------------------
start_date_line=$(grep 'start_date' "$wps_namelist")
end_date_line=$(grep 'end_date' "$wps_namelist")
fstart_date=$(echo "$start_date_line" | sed "s/.*= '\([^']*\)'.*/\1/")
fend_date=$(echo "$end_date_line" | sed "s/.*= '\([^']*\)'.*/\1/")

Start_year=`echo $fstart_date |cut -c1-4`
Start_month=`echo $fstart_date |cut -c6-7`
Start_date=`echo $fstart_date |cut -c9-10`
Start_hour=`echo $fstart_date |cut -c12-13`

End_year=`echo $fend_date |cut -c1-4`
End_month=`echo $fend_date |cut -c6-7`
End_date=`echo $fend_date |cut -c9-10`
End_hour=`echo $fend_date |cut -c12-13`

intervals=$(grep -i 'interval_seconds' $wps_namelist | awk -F= '{print $2}' | tr -d ' '|cut -c1-5)
start_date="${Start_year}-${Start_month}-${Start_date} ${Start_hour}:00:00"
end_date="${End_year}-${End_month}-${End_date} ${End_hour}:00:00"
start_timestamp=$(date -d "$start_date" +%s)
end_timestamp=$(date -d "$end_date" +%s)
current_timestamp="$start_timestamp"

# Checking for the existence of essential files
imdaafiles=`find $imdaa_data_path -name "*.grb2"`
unique_parts=$(echo "$imdaafiles" | xargs -n1 basename | cut -d '_' -f 5 | sort | uniq)
vapnd="CISOILM"
export parameters=($unique_parts)
essential_var=(CISOILM-L1 CISOILM-L2 CISOILM-L3 CISOILM-L4 HGT-prl LAND-sfc PRES-sfc PRMSL-msl RH-2m RH-prl TMP-2m TMP-prl TMP-sfc TSOIL-L1 TSOIL-L2 TSOIL-L3 TSOIL-L4 UGRD-10m UGRD-prl VGRD-10m VGRD-prl WEASD-sfc)
for var in "${essential_var[@]}"; do
  if [[ ! " ${parameters[@]} " =~ " ${var} " ]]; then
    echo -e "\n

						    FATAL ERROR
						    -----------
    The essential file '${RED}ncum_imdaa_reanl_HR_${var}_${Start_year}${Start_month}${Start_date}${Start_hour}-${End_year}${End_month}${End_date}${End_hour}.grb2${NC}' is not found in the downloaded IMDAA data.

    The essential variables to run wrf are:\n
                 1. ${BGreen}U component wind in pressure level${NC} (IMDAA DATA NAME: UGRD-prl)
                 2. ${BGreen}V component wind in pressure level${NC} (IMDAA DATA NAME: VGRD-prl)
                 3. ${BGreen}Temperature in pressure level${NC} (IMDAA DATA NAME: TMP-prl)
                 4. ${BGreen}Surface temperature${NC} (IMDAA DATA NAME: TMP-sfc)
                 5. ${BGreen}Geopotential height in pressure level${NC} (IMDAA DATA NAME: HGT-prl)
                 6. ${BGreen}Relative humidity in pressure level${NC} (IMDAA DATA NAME: RH-prl)
                 7. ${BGreen}2-meter Relative humidity${NC} (IMDAA DATA NAME: RH-2m)
                 8. ${BGreen}Land mask file${NC} (IMDAA DATA NAME: LAND-sfc)
                 9. ${BGreen}Surface pressure${NC} (IMDAA DATA NAME: PRES-sfc)
                10. ${BGreen}Mean sea level pressure${NC} (IMDAA DATA NAME: PRMSL-msl)
                11. ${BGreen}Soil temperature level 1${NC} (IMDAA DATA NAME: TSOIL-L1)
                12. ${BGreen}Soil temperature level 2${NC} (IMDAA DATA NAME: TSOIL-L2)
                13. ${BGreen}Soil temperature level 3${NC} (IMDAA DATA NAME: TSOIL-L3)
                14. ${BGreen}Soil temperature level 4${NC} (IMDAA DATA NAME: TSOIL-L4)
                15. ${BGreen}10-meter U wind${NC} (IMDAA DATA NAME: UGRD-10m)
                16. ${BGreen}10-meter V wind${NC} (IMDAA DATA NAME: VGRD-10m)
                17. ${BGreen}Soil moisture level 1${NC} (IMDAA DATA NAME: CISOILM-L1)
                18. ${BGreen}Soil moisture level 2${NC} (IMDAA DATA NAME: CISOILM-L2)
                19. ${BGreen}Soil moisture level 3${NC} (IMDAA DATA NAME: CISOILM-L3)
                20. ${BGreen}Soil moisture level 4${NC} (IMDAA DATA NAME: CISOILM-L4)
		21. ${BGreen}Water equivalent accumulated snow depth${NC} (IMDAA DATA NAME: WEASD-sfc)

    Please download all of the above variables before proceeding.\n
    Exiting ...
    \n"
    exit 1
  fi
done
parameters=("${essential_var[@]}")
soilparams=()
for varsx in "${parameters[@]}"; do
  if [[ $varsx == *CISOILM-L* ]]; then
    soilparams+=("$varsx")
  fi
done
other_list=()
for varsx in "${parameters[@]}"; do
  if [[ ! " ${soilparams[@]} " =~ " ${varsx} " ]]; then
    other_list+=("$varsx")
  fi
done
export newparameters=("${other_list[@]}" ${vapnd})

# Checking for the simulation date credibility
if [[ ( "$start_timestamp" -ge "$end_timestamp" ) ]]
then
        echo -e "\n
        \n
        ${RED}
        Simulation start time can not be higher than end time ${NC} ...
	-----------------------------------------------------

        Please check the simulation date correctly.
        \n"
        exit 1
fi

echo -e "\n
	\n
	\n
	\n
	\n
	\n
	\n
	\n
	\n
	\n
	\n
	\n
	\n
						Selecting serial or parallel run ...
	\n
	\n
	For parallel run type: ${BGreen}yes${NC}
	\n
	For serial run type: ${BGreen}no${NC}
	\n
	\n"
read -p "Do you want to go for a parallel run? (yes/no) " choice
choice="${choice,,}"
echo "${NC}"
mpich_check=$(mpirun --version 2>&1)
openmpi_check=$(mpirun --version 2>&1)

# Checking namelist.wps
cp -rf $wps_namelist namelist.wps.original
cp -rf $wps_namelist namelist.wps

namelistfile=namelist.wps
if grep -q 'opt_output_from_geogrid_path' "$namelistfile"; then
        sed -i "s|opt_output_from_geogrid_path.*|opt_output_from_geogrid_path = '$currdir',|g" $namelistfile
else
        sed -i "/&share/a \ opt_output_from_geogrid_path = '$currdir'" "$namelistfile"
fi

if grep -q "opt_geogrid_tbl_path" "$namelistfile"; then
        sed -i "s|opt_geogrid_tbl_path.*|opt_geogrid_tbl_path = '$currdir',|g" $namelistfile
else
        sed -i "/&geogrid/a \ opt_geogrid_tbl_path = '$currdir'" "$namelistfile"
fi

if grep -q 'opt_output_from_metgrid_path' "$namelistfile"; then
        sed -i "s|opt_output_from_metgrid_path.*|opt_output_from_metgrid_path = '$currdir',|g" $namelistfile
else
        sed -i "/&metgrid/a \ opt_output_from_metgrid_path = '$currdir'" "$namelistfile"
fi

if grep -q 'opt_metgrid_tbl_path' "$namelistfile"; then
        sed -i "s|opt_metgrid_tbl_path.*|opt_metgrid_tbl_path = '$currdir',|g" $namelistfile
else
        sed -i "/&metgrid/a \ opt_metgrid_tbl_path = '$currdir'" "$namelistfile"
fi

if grep -q 'geog_data_path' "$namelistfile"; then
	sed -i "s|geog_data_path.*|geog_data_path = '$wps_geog_path',|g" $namelistfile
else
        sed -i "/&geogrid/a \ geog_data_path = '$wps_geog_path'" "$namelistfile"
fi

#-----------------  pre-requisite library checking ------------------------------------------------------------------
# checking for mpi
if [ "$choice" = "yes" ]; then
	echo -e "\n

        You have opted for a ${BGreen}parallel${NC} run ...

        The selected number of processors: $nproc

        \n"
	sleep 1
	if [[ $mpich_check == *"MPICH"* ]]; then
		echo -e "\n
	${BGreen}MPICH is installed.${NC} Proceeding ...
		\n"
		sleep 0.5
		export RUN_COMMAND1="mpirun -np 1 ./ungrib.exe "
        	export RUN_COMMAND2="mpirun -np $nproc ./metgrid.exe "
        	export RUN_COMMAND3="mpirun -np $nproc ./geogrid.exe "
	elif [[ $openmpi_check == *"Open MPI"* ]]; then
    		echo -e "\n
	${BGreen}OpenMPI is installed.${NC} Proceeding ...
		\n"
		sleep 0.5
		export RUN_COMMAND1="mpirun -np 1 ./ungrib.exe "
        	export RUN_COMMAND2="mpirun -np $nproc ./metgrid.exe "
        	export RUN_COMMAND3="mpirun -np $nproc ./geogrid.exe "
	elif command -v mpiifort &>/dev/null; then
		echo -e "\n
        ${BGreen}Intel C compiler is installed.${NC} Proceeding ...
		\n"
		sleep 0.5
		export RUN_COMMAND1="mpirun -np 1 ./ungrib.exe "
                export RUN_COMMAND2="mpirun -np $nproc ./metgrid.exe "
                export RUN_COMMAND3="mpirun -np $nproc ./geogrid.exe "
	elif command -v mpiicc &>/dev/null; then
		echo -e "\n
        ${BGreen}Intel Fortran compiler is installed.${NC} Proceeding ...
		\n"
		sleep 0.5
		export RUN_COMMAND1="mpirun -np 1 ./ungrib.exe "
                export RUN_COMMAND2="mpirun -np $nproc ./metgrid.exe "
                export RUN_COMMAND3="mpirun -np $nproc ./geogrid.exe "
	else
    		echo -e "\n
		\n
		\n
		\n
		\n
		\n
		${BRed}
					FATAL ERROR ${NC}
					-----------
	
		Neither MPICH nor Openmpi nor Intel C compiler wrapper nor Intel 
		Fortran compiler wrapper is installed on this machine.

		${BGreen}
		Solutions${NC}:

                	1. Please install either of them before opting for a parallel run.

		Preferred website:
                
		${BLUE}https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compilation_tutorial.php${NC}
	       	
		Else go for ${BGreen}serial${NC} run.
		\n"
		exit
	fi
elif [ "$choice" = "no" ]; then
	echo -e "\n
	
	You have opted for a ${BGreen}serial${NC} run ...
	
	\n"
	sleep 0.5
	export RUN_COMMAND1="./ungrib.exe "
	export RUN_COMMAND2="./metgrid.exe "
	export RUN_COMMAND3="./geogrid.exe "
else
    echo -e "\n
    \n 
    \n 
    \n 
    \n 
    \n 
    ${BRed}
				    Invalid choice
				    --------------
    
    ${NC}Please enter '${BRed}yes${NC}' for parallel run or '${BRed}no${NC}' for serial run.
    
    ${BRed}
    Exiting ...${NC}
    \n"
    exit 1
fi

# checking for wgrib2
if command -v wgrib2 &>/dev/null; then
    echo -e "\n
    	${BGreen}WGRIB2 is installed.${NC} Proceeding ...
	\n"
	sleep 0.5
else
    echo -e "\n
    \n 
    \n 
    \n 
    \n 
    ${BRed}			wgrib2 is not installed${NC} 
    				-----------------------
    
    ${BGreen}
    Solutions${NC}:

    	1. Please install wgrib2 before proceeding.

    Preferred website:
    ${BLUE}https://www.cpc.ncep.noaa.gov/products/wesley/wgrib2/compile_questions.html#:~:text=1)%20Download%20ftp%3A%2F%2Fftp,1.2%20..
    \n"
    exit 1
fi

# checking for ncks
if command -v ncks &> /dev/null; then
    echo -e "\n
        ${BGreen}NCKS is installed.${NC} Proceeding ...
        \n"
        sleep 0.5
else
    echo -e "\n
    \n
    \n
    \n
    \n
    ${BRed}		NCKS is not installed${NC}
    			---------------------

    ${BGreen}
    Solutions${NC}:

    Please install ncks before proceeding.
    1. For Ubuntu/Debian: ${BGreen}sudo apt install nco${NC}
    2. For CentOS/RHEL: ${BGreen}sudo yum install nco${NC}
    3. For Fedora: ${BGreen}sudo dnf install nco${NC}
    4. For openSUSE: ${BGreen}sudo zypper install nco${NC}
    \n"
    exit 1
fi

# checking for ecCodes
mylistlength=${#essential_var[@]}
random_index=$((RANDOM % mylistlength))
random_element="${essential_var[$random_index]}"
found_imdaa_file=$(find "$imdaa_data_path" -type f -name "*_${random_element}_*")
rm -rf .eccodes_check.txt .eccodes_check1.txt
grib_dump $found_imdaa_file > .eccodes_check1.txt 2> .eccodes_check.txt
if command -v grib_set &> /dev/null; then
        if grep -i "ECCODES ERROR\|ecCodes assertion failed\| The environment variable ECCODES_DEFINITION_PATH is defined but incorrect\|The software is not correctly installed\|Unable to find boot.def" .eccodes_check.txt;
        then
                echo -e "\n
                \n
                \n
                \n
                \n
                \n
                \n
                \n
                \n
                ${BRed}
                                        ecCodes is installed, but not working properly${NC}
                                        ----------------------------------------------

                 (i) YOU SHOULD NOT GET ANY ERROR WHILE PERFORMING 'GRIB_DUMP' OR 'GRIB_SET' COMMAND \n
                (ii) Check these yourself. Do not proceed with this script if you are getting errors like
                     '${BRed}ECCODES ERROR : Unable to find boot.def.${NC}' or\n
                     '${BRed}ecCodes assertion failed:${NC}' or \n
                     '${BRed}The software is not correctly installed${NC}' or \n
                     '${BRed}The environment variable ECCODES_DEFINITION_PATH is defined but incorrect${NC}' or \n
                     '${BRed}Possible causes${NC}' after typing:


                                                grib_dump any-grib2-file
                ${BGreen}
                Solutions${NC}:

                Please install ecCodes using the shell (preferably not using conda) before proceeding.\n
                    1. For Ubuntu/Debian:       ${BGreen}sudo apt-get install libeccodes-tools${NC}
                    2. For CentOS/RHEL:         ${BGreen}sudo yum install eccodes-tools${NC}
                    3. For Fedora:              ${BGreen}sudo dnf install eccodes-tools${NC}
                    4. For openSUSE:            ${BGreen}sudo zypper install eccodes-tools${NC}
                    5. For Arch Linux:          ${BGreen}sudo pacman -S eccodes${NC}
                    \n"
                exit 1
        else
                echo -e "\n
                ${BGreen}
        ecCodes is installed.${NC} Proceeding ...
                \n"
                sleep 0.5
        fi
else
    echo -e "\n
    \n
    \n
    \n
    \n
    ${BRed}
                            ecCodes is not installed ${NC}
                            ------------------------

    ${BGreen}
    Solutions${NC}:

    Please install ecCodes (using shell, preferably not conda) before proceeding.\n
    1. For Ubuntu/Debian: ${BGreen}sudo apt-get install libeccodes-tools${NC}
    2. For CentOS/RHEL: ${BGreen}sudo yum install eccodes-tools${NC}
    3. For Fedora: ${BGreen}sudo dnf install eccodes-tools${NC}
    4. For openSUSE: ${BGreen}sudo zypper install eccodes-tools${NC}
    5. For Arch Linux: ${BGreen}sudo pacman -S eccodes${NC}
    \n"
    exit 1
fi
rm -rf .eccodes_check.txt .eccodes_check1.txt

# checking for netcdf4
if command -v ncdump &>/dev/null; then
    echo -e "\n
        ${BGreen}NETCDF4 is installed.${NC} Proceeding ...
	\n"
	sleep 0.5
else
    echo -e "\n
    \n 
    \n 
    \n 
    \n 
    ${BRed}		NETCDF4 is not installed${NC}
    			------------------------
    
    ${BGreen}
    Solutions${NC}:

    	1. Please install NETCDF4 before proceeding.

    Preferred website:
    ${BLUE}https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compilation_tutorial.php
    \n"
    exit 1
fi

# Checking for the existence of the WPS program
wpsprogram=$wps_path
if [ ! -d $wpsprogram ]
then
    echo -e "\n
    \n 
    \n 
    \n 
    \n 
    		The WPS program directory does not exist
		----------------------------------------
    
    ${BRed}Exiting ...${NC}
    \n"
    echo  -e "\n 
    \n 
    ${BRed}WPS program does not exist in the specified path:${NC} $wps_path
    Please fill all necessary fields correctly as mentioned. Then re-run the script.
    --------------------------------------------------------------------------------- 
    \n"
    exit 1
else
	wpsexe1=$wps_path/geogrid.exe
	wpsexe2=$wps_path/ungrib.exe
	wpsexe3=$wps_path/metgrid.exe
	if [ -x "$wpsexe1" ] && [ -x "$wpsexe2" ] && [ -x "$wpsexe3" ]; then
  		echo -e "\n
		${BGreen}
		geogrid.exe${NC}, ${BGreen}ungrib.exe${NC}, and ${BGreen}metgrid.exe${NC} exist and are executable. 
		
		Proceeding ...
		\n"
		sleep 0.5
	else
    		echo -e "\n 
		WPS folder exists. But one or more of the required files are missing or not executable"
	    	
		echo  -e "\n ${BRed}
    		\n 
    		\n 
    		\n 
    		\n 
    		\n 
				Executables do not exist in the specified path:${NC} $wps_path
				----------------------------------------------
		
		${BGreen}
		Solutions${NC}:
        	
		Please install the WPS suite properly so that all executables are built (geogrid.exe, ungrib.exe, and metgrid.exe).
		Then re-run the script.
		
		Preferred website:
		${BLUE}https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compilation_tutorial.php${NC}
	       	--------------------------------------------------------------------------------------------------------------------- 
		
		${BRed}
		Exiting ...${NC}
		\n"
		exit 1
	fi
fi
ln -sf ${wps_path}/*.exe .
ln -sf ${wps_path}/geogrid/GEOGRID.TBL.ARW GEOGRID.TBL 

#-------------------------------- sorting imdaa data ---------------------------------------------------
if $SORT_IMDAA; then
	echo -e "\n
	You have opted to sort IMDAA data.

	So, sorting ${BGreen}IMDAA${NC} data ...
	\n"
	rm -rf $currdir/rundata .imdaa_sorted
	mkdir $currdir/rundata
	while [ "$current_timestamp" -le "$end_timestamp" ]; do
		current_date=$(date -d "@$current_timestamp" +"%Y%m%d%H")
		rundate=$(date -d "@$current_timestamp" +"%Y%m%d")
  		current_hour=$(date -d "@$current_timestamp" +"%H")
        	for param in ${parameters[@]}
        	do
                	subset="${param}"
	                echo -e "\n
        	        Extracting ${BGreen}$subset${NC} from IMDAA ...
	                \n"
        	        sleep 0.5
	                found_file=$(find "$imdaa_data_path" -type f -name "*_${subset}_*")
        	        if [ -e "$found_file" ]; then
				if [ "$current_hour" -eq 0 ] || [ "$current_hour" -eq 6 ] || [ "$current_hour" -eq 12 ] || [ "$current_hour" -eq 18 ]
				then
					wgrib2 $found_file -match_fs "=${current_date}" -match_fs "anl" -grib_out $currdir/rundata/${param}_${rundate}_${current_hour}.grib2
                        	elif [ "$current_hour" -gt 0 ] && [ "$current_hour" -lt 6 ]
	                        then
	        	        	wgrib2 $found_file -match_fs "=${rundate}00" -match_fs "$(( 10#$current_hour )) hour fcst" -set_date ${current_date} -grib_out $currdir/rundata/${param}_${rundate}_$current_hour.grib2
        	        	elif [ "$current_hour" -gt 6 ] && [ "$current_hour" -lt 12 ]
                	        then
                        		apnd=$(( 10#${current_hour} - 6 ))
	                        	jj=`expr $apnd + 0`
        	                        wgrib2 $found_file -match_fs "=${rundate}06" -match_fs "$jj hour fcst" -set_date ${current_date} -grib_out $currdir/rundata/${param}_${rundate}_$current_hour.grib2
	                	elif [ "$current_hour" -gt 12 ] && [ "$current_hour" -lt 18 ]
        	               	then
                	               	wgrib2 $found_file -match_fs "=${rundate}12" -match_fs "$(( 10#${current_hour} - 12 )) hour fcst" -set_date ${current_date} -grib_out $currdir/rundata/${param}_${rundate}_$current_hour.grib2
	               	        elif [ "$current_hour" -gt 18 ]
        	               	then
               	                	wgrib2 $found_file -match_fs "=${rundate}18" -match_fs "$(( 10#${current_hour} - 18 )) hour fcst" -set_date ${current_date} -grib_out $currdir/rundata/${param}_${rundate}_$current_hour.grib2
	                       	fi
	                else
        	                echo -e "\n
                	        \n
	                        ${BRed}
				$param ${NC}does not found in ${BRed}${imdaa_data_path}${NC}
				-------------------------------------------------------------------------------------------------------------

        	                ${BGreen}
				Solutions${NC}:
                	                1. Either keep all downloaded files in a single folder, or \n
                        	        2. Correct the IMDAA data path provided in the user input section: \n
								$imdaa_data_path

	                        ${BRed}
				Exiting ...${NC}
        	                \n"
                	        exit 1
	                fi
        	done
		rm -rf $currdir/rundata/soilmois1 $currdir/rundata/soilmois2 $currdir/rundata/soilmois3
	        mkdir $currdir/rundata/soilmois1 $currdir/rundata/soilmois2 $currdir/rundata/soilmois3
		for soilp in ${soilparams[@]}
	        do
        		mv $currdir/rundata/${soilp}_${rundate}_${current_hour}.grib2 $currdir/rundata/soilmois1/
	                grib_set -s parameterCategory=0 $currdir/rundata/soilmois1/${soilp}_${rundate}_${current_hour}.grib2 $currdir/rundata/soilmois2/${soilp}_${rundate}_${current_hour}.grib2
		        grib_set -s parameterNumber=25 $currdir/rundata/soilmois2/${soilp}_${rundate}_${current_hour}.grib2 $currdir/rundata/soilmois3/${soilp}_${rundate}_${current_hour}.grib2
        	done
		current_timestamp=$((current_timestamp + intervals))
        	cat $currdir/rundata/soilmois3/*_${rundate}_${current_hour}.grib2 > $currdir/rundata/${vapnd}_${rundate}_${current_hour}.grib2
	done
fi
rm -rf $currdir/rundata/soilmois1 $currdir/rundata/soilmois2 $currdir/rundata/soilmois3

# Checking for the existence of the required IMDAA data
current_timestamp="$start_timestamp"
while [ "$current_timestamp" -le "$end_timestamp" ]; do
                current_date1=$(date -d "@$current_timestamp" +"%Y%m%d%H")
                rundate1=$(date -d "@$current_timestamp" +"%Y%m%d")
                current_hour1=$(date -d "@$current_timestamp" +"%H")
                for param in ${newparameters[@]}
                do
                        found_file=$(find "$currdir/rundata" -type f -name "${param}_${rundate1}_${current_hour1}.grib2")
                        if [ -e "$found_file" ]; then
                                actdate=`wgrib2 -s ${currdir}/rundata/${param}_${rundate1}_${current_hour1}.grib2| grep -oP 'd=\K\d{10}'| head -n 1`
                                if [ "$actdate" != "$current_date1" ]; then
                                        echo -e "\n
                                        \n
                                        \n
                                        \n
                                        \n
                                        \n
                                        ${RED}
	A mismatch between simulation time details and downloaded IMDAA data time details ${NC}
	---------------------------------------------------------------------------------

        parameter name: ${RED}${param}${NC}
        date: ${RED}${rundate1}${NC}
        interval time: ${RED}${current_hour1}${NC}

        ${BGreen}
        Solutions${NC}:

        1. File ${RED}${param}_${rundate1}_${current_hour1}.grib2${NC} does not contain any value. Make sure you have downloaded data (i.e., ${RED}${param}${NC}) for correct date (i.e., ${RED}${rundate1}${NC}) with proper time intervals (i.e., ${RED}${current_hour1}${NC}).

	2. If this variable (i.e., ${RED}${param}${NC}) not essential, then please remove from ${RED}$imdaa_data_path${NC}.
	
	3. Make sure you have kept all the downloaded data in a single folder. 
	
		Check the folder: ${RED}$imdaa_data_path${NC}
	
	4. Check the namelist.wps file, and make sure all the date details are as per convention.
           Example:${RED}
                   start_date<SPACE>=<SPACE>'YYYY-MM-DD1_HH:MM:SS'${NC},${RED}\n
                   end_date<SPACE>=<SPACE>'YYYY-MM-DD2_HH:MM:SS'${NC},

	5. Make sure whether ${RED}wgrib2${NC} and ${RED}eccodes${NC} work properly in your system or not.

        6. Check the time details of the data you have downloaded. Download the data as per your simulation date time and interval only.

        Can not proceed further. Exiting ...
        \n"
                                         exit 1
                                else
                                        echo -e "\n
                                        \n
        File ${BGreen}${param}_${rundate1}_${current_hour1}.grib2${NC} present and matching with simulation date.


	Proceeding ...
                                        \n"
                                        sleep 0.5
                                fi
                        else
                                echo -e "\n
                                \n
                                ${BRed}$param ${NC}is not found in ${BRed}${imdaa_data_path}${NC}
				---------------------------------------------------------------------------------------------

                                ${BGreen}
				Solutions${NC}:
                                        1. Either keep all downloaded files in a single folder or \n
                                        2. Correct the data path provided in the user input section.

                                ${BRed}Exiting ...${NC}
                                \n"
                                exit 1
                        fi
                done
                current_timestamp=$((current_timestamp + intervals))
		rm -rf .imdaa_sorted
		echo "IMDAA data sorted" >> .imdaa_sorted
done

#---------------------------------------------- geogrid section ------------------------------------------------------
if $RUN_GEOGRID; then
	echo -e "\n
	You have opted to run Geogrid.

	So, going for ${BGreen}GEOGRID${NC} run ...
	\n"
	rm -rf geo_em.d0* .namelist.wps.geogrid geogrid.log geogrid.log.0000 .log_geogrid.out
	sleep 0.5

	if [ ! -e "GEOGRID.TBL" ] && [ ! -e "$namelistfile" ]; then
                echo -e "\n
                ${BRed}
						FATAL ERROR
						-----------\n
		Either GEOGRID.TBL is not present or the namelist.wps file does not exist.${NC}

		Can not go for GEOGRID.EXE \n

                ${BGreen}
		Solutions${NC}:
                
			1. Do not terminate the script in mid-way or delete any files while the script is running. 
			   Let set all true (SORT_IMDAA=true, RUN_GEOGRID=true, and RUN_UNGRIB=true) and re-run the script.
                \n
                \n
		Exiting ...
		\n"
                exit 1
        fi
	# checking for the existence of static data
	staticdata=$wps_geog_path
	if [ -d "$staticdata" ]; then
  		if [ "$(ls -A "$staticdata")" ]; then
        		echo -e "\n
        		WPS_GEOG static data folder ${BGreen}exists${NC} and ${BGreen}not empty${NC}.
	
	       		 Proceeding ...
        		\n"
        		sleep 0.5
	  	else
        		echo -e "\n
			\n
		        \n
	       		\n
	       		\n
	       		\n
			${BRed}
					WPS_GEOG directory exists but is empty${NC}
					--------------------------------------
	
	        	${BGreen}
			Solutions${NC}:
	
		        Please check the contents of the WPS_GEOG folder and make sure it has all the static data.
		        then re-run the script.
	
		        Exiting ...
		        \n"
		        exit 1
		  fi
	else
	        echo -e "
			        The WPS_GEOG folder does not exist
				----------------------------------
	       
		${BRed}Exiting ...${NC}
        	\n"
	        echo  -e "\n
        	\n
        	\n
        	\n
	        ${BRed}
		WPS_GEOG folder does not exist in the specified path:${NC} $wps_geog_path

       		${BGreen}
		Solutions${NC}:

	        Please correctly fill the WPS_GEOG folder path as mentioned. Then re-run the script.
       		-------------------------------------------------------------------------------------
	        \n"
       		exit 1
	fi
	echo -e "\n
	\n
	\n
	\n
	\n
	${BGreen}
				Extracting and sorting variables from downloaded IMDAA data completed.${NC}
	\n
	\n
	\n
	Proceeding for ${BGreen}GEOGRID${NC} ...
	\n
        \n"
	${RUN_COMMAND3}  > .log_geogrid.out 2>&1

	export GEOFILE1=geogrid.log
	export GEOFILE2=geogrid.log.0000
	if [ -f "$GEOFILE1" ]; then
        	until [[ ( ! -z $geogridlog ) ]]
	        do
        	        geogridlog=`cat $GEOFILE1 |tail -n100 |grep  "Successful completion of program geogrid.exe"`
	                if [[ ( -z $geogridlog ) ]]
        	        then
				rm -rf .geogrid_error
				cat .log_geogrid.out |grep ERROR>> .geogrid_error
				reso1="1deg"
				reso2="10m"
				reso3="5m"
				reso4="2m"
				reso5="30s"
				if [[ "`cat .geogrid_error`" == *"$reso1"* ]]; then
  					echo -e "\n
					\n
                                        \n
                                        \n
                                        \n
                                        \n
					\n
					${RED}
							FATAL ERROR${NC}
							-----------


Static data resolution error. \n
Opted resolution (i.e., ${RED}$reso1${NC}) data not available in ${RED}WPS_GEOG${NC} folder: \n
	${RED}${wps_geog_path} ${NC}\n
Either download the datasets as per resolution or go for other available resolutions (${BGreen}$reso5${NC} or ${BGreen}$reso2${NC} or ${BGreen}$reso3${NC} or ${BGreen}$reso4${NC} if present in ${wps_geog_path}; check before opting) or '${BGreen}default${NC}' in ${BGreen}geog_data_res${NC} option under ${BGreen}geogrid section${NC} of ${BGreen}namelist.wps${NC}.\n

Preferred website for downloading the static data:${BLUE}\n
	http://www2.mmm.ucar.edu/wrf/users/download/get_sources_wps_geog.html${NC}\n

Exiting ...
					\n"
					exit 1
				elif [[ "`cat .geogrid_error`" == *"$reso2"* ]]; then
					echo -e "\n
                                        \n
                                        \n
                                        \n
                                        \n
                                        \n
                                        \n
                                        ${RED}
                                                        FATAL ERROR${NC}
							-----------


Static data resolution error. \n
Opted resolution (i.e., ${RED}$reso2${NC}) data not available in ${RED}WPS_GEOG${NC} folder: \n
	${RED}${wps_geog_path} ${NC}\n
Either download the datasets as per resolution or go for other available resolutions (${BGreen}$reso1${NC} or ${BGreen}$reso5${NC} or ${BGreen}$reso3${NC} or ${BGreen}$reso4${NC} if present in ${wps_geog_path}; check before opting) or '${BGreen}default${NC}' in ${BGreen}geog_data_res${NC} option under ${BGreen}geogrid section${NC} of ${BGreen}namelist.wps${NC}.\n

Preferred website for downloading the static data:${BLUE}\n
	http://www2.mmm.ucar.edu/wrf/users/download/get_sources_wps_geog.html${NC}\n

Exiting ...
                                        \n"
                                        exit 1
				elif [[ "`cat .geogrid_error`" == *"$reso3"* ]]; then
					echo -e "\n
                                        \n
                                        \n
                                        \n
                                        \n
                                        \n
                                        \n
                                        ${RED}
                                                        FATAL ERROR${NC}
							-----------


Static data resolution error. \n
Opted resolution (i.e., ${RED}$reso3${NC}) data not available in ${RED}WPS_GEOG${NC} folder: \n
                                ${RED}${wps_geog_path} ${NC}\n
Either download the datasets as per resolution or go for other available resolutions (${BGreen}$reso1${NC} or ${BGreen}$reso2${NC} or ${BGreen}$reso5${NC} or ${BGreen}$reso4${NC} if present in ${wps_geog_path}; check before opting) or '${BGreen}default${NC}' in ${BGreen}geog_data_res${NC} option under ${BGreen}geogrid section${NC} of ${BGreen}namelist.wps${NC}.\n

Preferred website for downloading the static data:${BLUE}\n
	http://www2.mmm.ucar.edu/wrf/users/download/get_sources_wps_geog.html${NC}\n

Exiting ...
                                        \n"
                                        exit 1
				elif [[ "`cat .geogrid_error`" == *"$reso4"* ]]; then
					echo -e "\n
                                        \n
                                        \n
                                        \n
                                        \n
                                        \n
                                        \n
                                        ${RED}
                                                        FATAL ERROR${NC}
							-----------


Static data resolution error. \n
Opted resolution (i.e., ${RED}$reso4${NC}) data not available in ${RED}WPS_GEOG${NC} folder: \n
                                ${RED}${wps_geog_path} ${NC}\n
Either download the datasets as per resolution or go for other available resolutions (${BGreen}$reso1${NC} or ${BGreen}$reso2${NC} or ${BGreen}$reso3${NC} or ${BGreen}$reso5${NC} if present in ${wps_geog_path}; check before opting) or '${BGreen}default${NC}' in ${BGreen}geog_data_res${NC} option under ${BGreen}geogrid section${NC} of ${BGreen}namelist.wps${NC}.\n

Preferred website for downloading the static data:${BLUE}\n
	http://www2.mmm.ucar.edu/wrf/users/download/get_sources_wps_geog.html${NC}\n

Exiting ...
                                        \n"
                                        exit 1
				elif [[ "`cat .geogrid_error`" == *"$reso5"* ]]; then
					echo -e "\n
                                        \n
                                        \n
                                        \n
                                        \n
                                        \n
                                        \n
                                        ${RED}
                                                        FATAL ERROR${NC}
							-----------


Static data resolution error. \n
\n
Opted resolution (i.e., ${RED}$reso5${NC}) data not available in ${RED}WPS_GEOG${NC} folder: \n
				${RED}${wps_geog_path} ${NC}\n
Either download the datasets as per resolution or go for other available resolutions (${BGreen}$reso1${NC} or ${BGreen}$reso2${NC} or ${BGreen}$reso3${NC} or ${BGreen}$reso4${NC} if present in ${wps_geog_path}; check before opting) or '${BGreen}default${NC}' in ${BGreen}geog_data_res${NC} option under ${BGreen}geogrid section${NC} of ${BGreen}namelist.wps${NC}.\n

Preferred website for downloading the static data:${BLUE}\n
	http://www2.mmm.ucar.edu/wrf/users/download/get_sources_wps_geog.html${NC}\n

Exiting ...
                                        \n"
                                        exit 1
				else
                	       		echo -e "\n
		  			\n 
	  				\n 
	  				\n 
	  				\n 
		  			\n 
  					\n 
					${RED}
								FATAL ERROR
								-----------
  					\n 
  					\n 
  					\n 
					GEOGRID${NC} is not successfully finished.
	
					${BGreen}
					Possible solutions${NC}:
       	      
     						1. Check the geogrid log thoroughly to locate the error source: ${RED}.log_geogrid.out${NC}.
						
						2. Check for ${RED}GEOGRID.TBL${NC} if it exists?
	
       		 	                        3. Issue in WPS_GEOG static data, ${RED}maybe some necessary folders are missing${NC}.
						
						4. Check namelist.wps ${RED}thoroughly${NC} for any incorrect entry.
						
						6. Check whether ${RED}GEOGRID.TBL.ARW${NC} exists in${RED} $wps_path/geogrid${NC}? 
						
						7. This Could be due to ${RED}incorrect mpi operation${NC}, try with a serial run.
					\n"
	       			        exit 1
				fi
        	        else
				min_lon=`ncks -H -C -v XLONG_M geo_em.d01.nc | grep -oE '[-]?[0-9]+\.[0-9]+'| awk '{print $1}'|sort -n| head -n 1| awk '{print int($1)}'`
	        	        max_lon=`ncks -H -C -v XLONG_M geo_em.d01.nc | grep -oE '[-]?[0-9]+\.[0-9]+'| awk '{print $1}'|sort -n| tail -n 1| awk '{print int($1)}'`
        	        	min_lat=`ncks -H -C -v XLAT_M geo_em.d01.nc | grep -oE '[-]?[0-9]+\.[0-9]+'| awk '{print $1}'|sort -n| head -n 1| awk '{print int($1)}'`
                		max_lat=`ncks -H -C -v XLAT_M geo_em.d01.nc | grep -oE '[-]?[0-9]+\.[0-9]+'| awk '{print $1}'|sort -n| tail -n 1| awk '{print int($1)}'`

                        	if [ "$min_lon" -lt 30 ] || [ "$max_lon" -ge 120 ] || [ "$min_lat" -lt -15 ] || [ "$max_lat" -ge 45 ]
	        	            then
        	                        echo -e "\n
			                	                FATAL ERROR
								-----------
                        	        
                                	${RED}Model parent domain is outside the IMDAA data region. ${NC}
	                                
        	                        Can not proceed for UNGRIB and METGRID.
                	                \n"
                        	        exit 1
	                        else
        	                        echo -e "\n 
                	                ${BGreen}GEOGRID${NC} is finished and within the IMDAA data region. 
				
	                                	Going for ${BGreen}UNGRIB${NC} run ...
        	                        \n"
					cp -rf $namelistfile .namelist.wps.geogrid
                	                rm -rf .log_geogrid.out
					rm -rf .geogrid_done
					echo "Process geogrid completed." >> .geogrid_done
                        	        break
	                        fi
			fi
		done
	elif [ -f "$GEOFILE2" ]; then
                until [[ ( ! -z $geogridlog ) ]]
                do
                        geogridlog=`cat $GEOFILE2 |tail -n100 |grep  "Successful completion of program geogrid.exe"`
                        if [[ ( -z $geogridlog ) ]]
                        then
                                rm -rf .geogrid_error
                                cat .log_geogrid.out |grep ERROR>> .geogrid_error
                                reso1="1deg"
                                reso2="10m"
                                reso3="5m"
                                reso4="2m"
                                reso5="30s"
                                if [[ "`cat .geogrid_error`" == *"$reso1"* ]]; then
                                        echo -e "\n
                                        \n
                                        \n
                                        \n
                                        \n
                                        \n
                                        \n
                                        ${RED}
                                                        FATAL ERROR${NC}
							-----------


Static data resolution error. \n
Opted resolution (i.e., ${RED}$reso1${NC}) data not available in ${RED}WPS_GEOG${NC} folder: \n
        ${RED}${wps_geog_path} ${NC}\n
Either download the datasets as per resolution or go for other available resolutions (${BGreen}$reso5${NC} or ${BGreen}$reso2${NC} or ${BGreen}$reso3${NC} or ${BGreen}$reso4${NC} if present in ${wps_geog_path}; check before opting) or '${BGreen}default${NC}' in ${BGreen}geog_data_res${NC} option under ${BGreen}geogrid section${NC} of ${BGreen}namelist.wps${NC}.\n

Preferred website for downloading the static data:${BLUE}\n
        http://www2.mmm.ucar.edu/wrf/users/download/get_sources_wps_geog.html${NC}\n

Exiting ...
                                        \n"
                                        exit 1
                                elif [[ "`cat .geogrid_error`" == *"$reso2"* ]]; then
                                        echo -e "\n
                                        \n
                                        \n
                                        \n
                                        \n
                                        \n
                                        \n
                                        ${RED}
                                                        FATAL ERROR${NC}
							-----------


Static data resolution error. \n
Opted resolution (i.e., ${RED}$reso2${NC}) data not available in ${RED}WPS_GEOG${NC} folder: \n
        ${RED}${wps_geog_path} ${NC}\n
Either download the datasets as per resolution or go for other available resolutions (${BGreen}$reso1${NC} or ${BGreen}$reso5${NC} or ${BGreen}$reso3${NC} or ${BGreen}$reso4${NC} if present in ${wps_geog_path}; check before opting) or '${BGreen}default${NC}' in ${BGreen}geog_data_res${NC} option under ${BGreen}geogrid section${NC} of ${BGreen}namelist.wps${NC}.\n

Preferred website for downloading the static data:${BLUE}\n
        http://www2.mmm.ucar.edu/wrf/users/download/get_sources_wps_geog.html${NC}\n

Exiting ...
                                        \n"
                                        exit 1
                                elif [[ "`cat .geogrid_error`" == *"$reso3"* ]]; then
                                        echo -e "\n
                                        \n
                                        \n
                                        \n
                                        \n
                                        \n
                                        \n
                                        ${RED}
                                                        FATAL ERROR${NC}
							-----------


Static data resolution error. \n
Opted resolution (i.e., ${RED}$reso3${NC}) data not available in ${RED}WPS_GEOG${NC} folder: \n
                                ${RED}${wps_geog_path} ${NC}\n
Either download the datasets as per resolution or go for other available resolutions (${BGreen}$reso1${NC} or ${BGreen}$reso2${NC} or ${BGreen}$reso5${NC} or ${BGreen}$reso4${NC} if present in ${wps_geog_path}; check before opting) or '${BGreen}default${NC}' in ${BGreen}geog_data_res${NC} option under ${BGreen}geogrid section${NC} of ${BGreen}namelist.wps${NC}.\n

Preferred website for downloading the static data:${BLUE}\n
        http://www2.mmm.ucar.edu/wrf/users/download/get_sources_wps_geog.html${NC}\n

Exiting ...
                                        \n"
                                        exit 1
                                elif [[ "`cat .geogrid_error`" == *"$reso4"* ]]; then
                                        echo -e "\n
                                        \n
                                        \n
                                        \n
                                        \n
                                        \n
                                        \n
                                        ${RED}
                                                        FATAL ERROR${NC}
							-----------


Static data resolution error. \n
Opted resolution (i.e., ${RED}$reso4${NC}) data not available in ${RED}WPS_GEOG${NC} folder: \n
                                ${RED}${wps_geog_path} ${NC}\n
Either download the datasets as per resolution or go for other available resolutions (${BGreen}$reso1${NC} or ${BGreen}$reso2${NC} or ${BGreen}$reso3${NC} or ${BGreen}$reso5${NC} if present in ${wps_geog_path}; check before opting) or '${BGreen}default${NC}' in ${BGreen}geog_data_res${NC} option under ${BGreen}geogrid section${NC} of ${BGreen}namelist.wps${NC}.\n

Preferred website for downloading the static data:${BLUE}\n
        http://www2.mmm.ucar.edu/wrf/users/download/get_sources_wps_geog.html${NC}\n

Exiting ...
                                        \n"
                                        exit 1
                                elif [[ "`cat .geogrid_error`" == *"$reso5"* ]]; then
                                        echo -e "\n
                                        \n
                                        \n
                                        \n
                                        \n
                                        \n
                                        \n
                                        ${RED}
                                                        FATAL ERROR${NC}
							-----------


Static data resolution error. \n
\n
Opted resolution (i.e., ${RED}$reso5${NC}) data not available in ${RED}WPS_GEOG${NC} folder: \n
                                ${RED}${wps_geog_path} ${NC}\n
Either download the datasets as per resolution or go for other available resolutions (${BGreen}$reso1${NC} or ${BGreen}$reso2${NC} or ${BGreen}$reso3${NC} or ${BGreen}$reso4${NC} if present in ${wps_geog_path}; check before opting) or '${BGreen}default${NC}' in ${BGreen}geog_data_res${NC} option under ${BGreen}geogrid section${NC} of ${BGreen}namelist.wps${NC}.\n

Preferred website for downloading the static data:${BLUE}\n
        http://www2.mmm.ucar.edu/wrf/users/download/get_sources_wps_geog.html${NC}\n

Exiting ...
                                        \n"
                                        exit 1
                                else
                                        echo -e "\n
                                        \n
                                        \n
                                        \n
                                        \n
                                        \n
                                        \n
                                        ${RED}
                                                                FATAL ERROR
								-----------
                                        \n
                                        \n
                                        \n
                                        GEOGRID${NC} is not successfully finished.

                                        ${BGreen}
                                        Possible solutions${NC}:

                                                1. Check the geogrid log thoroughly to locate the error source: ${RED}.log_geogrid.out${NC}.

                                                2. Check for ${RED}GEOGRID.TBL${NC} if it exists?

                                                3. Issue in WPS_GEOG static data, ${RED}maybe some necessary folders are missing${NC}.

                                                4. Check namelist.wps ${RED}thoroughly${NC} for any incorrect entry.

                                                6. Check whether ${RED}GEOGRID.TBL.ARW${NC} exists in${RED} $wps_path/geogrid${NC}?

                                                7. This Could be due to ${RED}incorrect mpi operation${NC}, try with a serial run.
                                        \n"
                                        exit 1
                                fi
                        else
                                min_lon=`ncks -H -C -v XLONG_M geo_em.d01.nc | grep -oE '[-]?[0-9]+\.[0-9]+'| awk '{print $1}'|sort -n| head -n 1| awk '{print int($1)}'`
                                max_lon=`ncks -H -C -v XLONG_M geo_em.d01.nc | grep -oE '[-]?[0-9]+\.[0-9]+'| awk '{print $1}'|sort -n| tail -n 1| awk '{print int($1)}'`
                                min_lat=`ncks -H -C -v XLAT_M geo_em.d01.nc | grep -oE '[-]?[0-9]+\.[0-9]+'| awk '{print $1}'|sort -n| head -n 1| awk '{print int($1)}'`
                                max_lat=`ncks -H -C -v XLAT_M geo_em.d01.nc | grep -oE '[-]?[0-9]+\.[0-9]+'| awk '{print $1}'|sort -n| tail -n 1| awk '{print int($1)}'`

                                if [ "$min_lon" -lt 30 ] || [ "$max_lon" -ge 120 ] || [ "$min_lat" -lt -15 ] || [ "$max_lat" -ge 45 ]
                                    then
                                        echo -e "\n
			                                       FATAL ERROR
							       -----------

                                        ${RED}Model parent domain is outside the IMDAA data region. ${NC}

                                        Can not proceed for UNGRIB and METGRID.
                                        \n"
                                        exit 1
                                else
                                        echo -e "\n
                                        ${BGreen}GEOGRID${NC} is finished and within the IMDAA data region.

                                                Going for ${BGreen}UNGRIB${NC} run ...
                                        \n"
                                        cp -rf $namelistfile .namelist.wps.geogrid
                                        rm -rf .log_geogrid.out
                                        rm -rf .geogrid_done
                                        echo "Process geogrid completed." >> .geogrid_done
                                        break
                                fi
                        fi
                done
	else
        	sleep 0.5
	        echo  -e "\n 
  		\n 
  		\n 
  		\n 
  		\n 
  		\n 
		${BRed}
				FATAL ERROR ${NC}
				-----------
		
		GEOGRID is not completed. 
		
		${BGreen}Possible solutions${NC}: 
			1. Check the .log_geogrid.out file to locate the error source 
		\n"
		exit 1
	fi
fi
#------------------------------- ungrib section -------------------------------------------------------------------
if $RUN_UNGRIB; then
	echo -e "\n
	You have opted to run ungrib.

	So, going for ${BGreen}UNGRIB${NC} run ...
	\n"
	rm -rf .log_ungrib_* .ungrib_done ungrib.log .namelist.wps.ungrib
	cp -rf .namelist.wps.geogrid $namelistfile
	sed -i 's/fg_name.*/fg_name =/g' $namelistfile
	if [ ! -e ".imdaa_sorted" ] && [ ! -e "$namelistfile" && [ ! -e "Vtable" ]; then
		echo -e "\n
						FATAL ERROR
						----------- \n
		${BRed}Either IMDAA data is not sorted or the namelist.wps file or Vtable does not exist.${NC}

		${BGreen}
		Solutions${NC}:
			1. Set SORT_IMDAA=true in user_input.sh file \n
			2. Do not terminate the script in mid-way or delete any files while the script is running. Let set all true (SORT_IMDAA=true, RUN_GEOGRID=true, and RUN_UNGRIB=true) and re-run the script.
		\n"
		exit 1
	fi
	for param in ${newparameters[@]} 
	do
		echo -e "\n Running ungrib for ${param} ..."
		sed -i "s/prefix.*/prefix = '${param}',/g" $namelistfile
		sleep 0.5
		str0=`cat $namelistfile|grep fg_name`
		str1="${str0}"
		str2=${param}
		str3=${str1}\'${str2}\'
		sed -i "s/ fg_name.*/${str3},/g" $namelistfile
		rm -rf GRIBFILE* ${param}:* 
		${wps_path}/link_grib.csh $currdir/rundata/${param}_*
	
		${RUN_COMMAND1}  > .log_ungrib_${param} 2>&1

		until [[ ( ! -z $ungriblog ) ]]
			do
			ungriblog=`cat .log_ungrib_${param} |tail -n100 |grep  "Successful completion of ungrib."`
			if [[ ( -z $ungriblog ) ]] 
			then
				echo -e "\n
	  			\n 
  				\n 
  				\n 
  				\n 
  				\n 
							FATAL ERROR
							----------- \n
				${BRed}ungrib for ${param} ${NC}is not finished, exiting ...
	
				${BGreen}Possible actions${NC}:
			                1. Check the .log_ungrib_${param} file to locate the error source.\n
					2. Check all libraries whether all working fine or not: MPI, WGRIB2, NCKS, ECCODES, NETCDF4\n
					3. If nothing is traced, might be due to data inconsistency. The solution is not in your hands. Contact NCMRWF.
				\n"
				exit 1
			else
				continue 
			fi
		done
		echo -e "\n
		\n
		\n
				Ungrib for ${BGreen}${param} ${NC} is finished. Going for the next variable ...
		\n
		\n
		\n"
	done
	cp -rf $namelistfile .namelist.wps.ungrib
	rm -rf .ungrib_done
	echo "Process ungrib completed." >> .ungrib_done
fi
#------------------------------- metgrid section -------------------------------------------------------------------
rm -rf .log_metgrid metgrid.log* .remove_ungrib_data .success .unsuccess
cat > .unsuccess << EOF
#!/bin/bash
echo -e "\n	
\n
\n
\n
\n
\n

		${RED}${BRed}				FATAL ERROR

		Can not go for Metgrid...
		${NC}
                --------------------------------------------------------------------------------------------------------------
                The reason for not proceeding with metgrid is due to the below red-colored files.

		If you wish to proceed for metgrid, you need to remove this particular variable downloaded in:\n
					${BGreen}$imdaa_data_path${NC}
                
		P.S.: If this is an essential parameter for you, please Raise a concern to NCMRWF for clarifications.

                ------------------------------------------------------------------------------------------------------------- \n"
EOF

all_non_zero=true
rm -rf .z
for file in "${newparameters[@]}"; do
	for hour in $(eval echo "{00..23..$(( $intervals / 3600 ))}")
        do
        	ss=("$file":"$Start_year"-"$Start_month"-"$Start_date"_"$hour")
                if [ -e "$ss" ]; then
			file_size=$(stat -c %s "$ss")
			if [ "$file_size" -eq 0 ]; then
				all_non_zero=false
				echo -e "File ${RED}$ss ${NC}is empty. "  >> .z
			fi
		else
			echo -e "\n
			\n
			\n
			\n
			\n
			\n
			File ${BRed}$ss${NC} does not exist.
			\n"
			all_non_zero=false
        	fi
	done
done

if $all_non_zero; then
	echo -e "\n
	\n
	\n
	\n
	\n
	\n
	\n
	\n
				Successfully finished ${BGreen} Ungrib ${NC}for all parameters.
	\n
	\n

	Proceeding for ${BGreen}METGRID${NC} ...
	\n
	\n
	\n"
	rm -rf met_em.d0*	
	dom=`grep 'max_dom' $namelistfile | awk '{print $3}' | tr -d ','`
	if [ -e ".ungrib_done" ]; then
		if [ -e ".geogrid_done" ] && [ "${dom}" -eq `ls geo_em.d0*.nc|wc -l` ]; then
			if [ -e "METGRID.TBL" ]; then
				cp -rf .namelist.wps.ungrib $namelistfile
				${RUN_COMMAND2}  > .log_metgrid 2>&1
				sleep 1
			else
				echo -e "\n
		                ${BRed}			FATAL ERROR \n
							-----------

				METGRID.TBL does not exist.${NC}

		                ${BGreen}
				Solutions${NC}:

                        		1. Do not terminate the script in mid-way or delete any files while the script is running. \n
					2. Let set all true (SORT_IMDAA=true, RUN_GEOGRID=true, and RUN_UNGRIB=true) and re-run the script.
		                \n"
				exit 1
			fi
		else
			echo -e "\n
			
			${BRed}			FATAL ERROR
						-----------

			Geogrid, not completed${NC}. Please go for Geogrid before going to METGRID.${BGreen}
			
			Solutions${NC}:
			
			set ${BGreen}RUN_GEOGRID=true${NC} in user_input.sh file
			\n"
			exit 1
		fi
	else
		echo -e "\n
		${BRed}			FATAL ERROR \n
					-----------
		
		Ungrib, not completed${NC}. Please go for ungrib before going to METGRID.
		${BGreen}

		Solutions${NC}:

		set ${BGreen}RUN_UNGRIB=true${NC} in user_input.sh file
		
		\n"
		exit 1
	fi
else
	echo -e "\n
	\n
	\n
	\n
	\n
	\n
        ${BLUE}
	Successfully finished UNGRIB for all parameters.${NC}

        But, ${BRed}some files have zero size${NC}. Hence, can not proceed with the METGRID.
	
	Checking for files that have issues ...
        \n"
	bash .unsuccess
	cat .z
    	exit 1
fi

# checking for success
metfile1=(met_em.d01.${fstart_date}.nc)
echo $metfile1
if [ -e "$metfile1" ]; then
	ncdump -h $metfile1>.metfile2
	val=`ncdump -h $metfile1 |grep NUM_METGRID_SOIL_LEVELS |awk {'print $3'}`
	num_met_land_cat=`ncdump -h $metfile1 |grep NUM_LAND_CAT |awk {'print $3'}`
	num_met_level=`ncdump -h $metfile1 |grep num_metgrid_levels |awk {'print $3'}|tr "\n" " "|cut -c1-2`
else
	echo -e "\n
	${RED}
					FATAL ERROR
					----------- \n
	$metfile1 does not exists !!!${NC}
	\n
	
	Metgrid may be successful, but accuracy can not be checked. Does not guarantee WRF success.

	Cause:
		1. There is no parent domain for this simulation. 
	\n"
fi
cat > .remove_ungrib_data << EOF
#!/bin/bash
for param in ${newparameters[@]}
do
        rm -rf \${param}:*
done
EOF

cat > .success << EOF
#!/bin/bash

echo -e "\n
        \n
        \n
        \n
        \n
        \n
|---------------------------------------------------------------------------------------------------------------------------------------
|
|
|                                      ---------------------------------------------
|                                      |                                           |
|                                      |                 ${BGreen}SUCCESS${NC}                   |
|                                      |                                           |
|                                      ---------------------------------------------
|
|
|                       WPS completed. Creating intermediate files using geogrid, ungrib, and metgrid is done.
|
|
|			       Please proceed with ${BGreen}real.exe${NC} and ${BGreen}wrf.exe${NC} in the conventional way.
|
|
|
|       Useful information for the namelist.input (as per the current data):
|
|                1. NUM_METGRID_LEVELS = ${BGreen}${val}${NC}
|
|                2. NUM_SOIL_LAYERS = ${BGreen}${val}${NC}
|
|                3. NUM_LAND_CAT = ${BGreen}${num_met_land_cat}${NC}
|
|                4. NUM_METGRID_SOIL_LEVELS = ${BGreen}${num_met_level}${NC}
|
|--------------------------------------------------------------------------------------------------------------------------------------- \n"

EOF
chmod +x .success
chmod +x .remove_ungrib_data

export METFILE1=metgrid.log
export METFILE2=metgrid.log.0000
if [ -f "$METFILE1" ]; then
        until [[ ( ! -z $metgridlog ) ]]
        do
                metgridlog=`cat $METFILE1 |tail -n100 |grep  "Successful completion of program metgrid.exe"`
                if [[ ( -z $metgridlog ) ]]
                then
                        echo -e "\n
			\n
			\n
			\n
			\n
			\n
			
			${RED}
							METGRID is not successful ${NC}
							-------------------------

			${BGreen}
			Possible actions${NC}:

				1. Check whether the geogrid output file is there or not (e.g., geo_em.d01.nc).
			   	   If not, then please set ${RED}true${NC} for the RUN_GEOGRID option in user_input.sh file.

				2. Check the .log_metgrid file to locate the error.

				3. Check for missing of any ${RED}essential variable${NC} in the ${BLUE}parameters${NC} option.
			           Please add all essential parameters to the list.

				4. Check whether all these libraries are working fine or not: NETCDF4, WGRIB2, NCKS, ECCODES, MPI
					
			\n"
			exit 1
                else
                        echo -e "\n 
			${BGreen}
			METGRID${NC} is finished. 
			\n
			\n
			\n
			\n
			Checking for accuracy ... 
			\n
			\n
			\n
			\n
			\n"
			if [ "$val" -gt 0 ]; then
				bash .remove_ungrib_data
				rm -rf .log_* GRIBFILE* .metfile2 .remove_ungrib_data
				bash .success
				break
			else
				echo -e "\n
			       	The metgrid is finished.
				\n
				\n
				\n
			       	However, there is an issue with the ${BRed}metgrid soil level${NC}. 
				\n
				
				Do not go for the WRF run.
				\n"
				exit 1
			fi
                fi
        done
elif [ -f "$METFILE2" ]; then
        until [[ ( ! -z $metgridlog ) ]]
        do
                metgridlog=`cat $METFILE2 |tail -n100 |grep  "Successful completion of program metgrid.exe"`
                if [[ ( -z $metgridlog ) ]]
                then
                        echo -e "\n
			\n
			\n
			\n
			\n
			\n

			${RED}
							METGRID is not successful ${NC}
							-------------------------

                        ${BGreen}
			Possible actions${NC}:

                        	1. Check whether the geogrid output file is there or not (e.g., geo_em.d01.nc).
				   If not, then please set ${RED}true${NC} for the RUN_GEOGRID option in user_input.sh file.

                        	2. Check the .log_metgrid file to locate the error.

				3. Check for missing of any ${RED}essential variable${NC} in the ${BLUE}parameters${NC} option.
                                   Please add all essential parameters to the list.

       				4. Check whether all these libraries are working fine or not: NETCDF4, WGRIB2, NCKS, ECCODES, MPI
                        
			\n"
                        exit 1
                else
			echo -e "\n ${BGreen}
			METGRID${NC} is finished.
			\n
			\n
			Checking for accuracy ... 
			\n"
                        if [ "$val" -gt 0 ]; then
				bash .remove_ungrib_data
                                rm -rf .log_* GRIBFILE* .metfile2 .remove_ungrib_data
				bash .success
                                break
                        else
                                echo -e "\n
			       	Metgrid is finished, however, there is an issue in the ${BRed}metgrid soil level${NC}. 
				
				Do not go for the WRF run. It might be due to data inconsistency, solution is not in your hands.

				Contact NCMRWF!
				\n"
                                exit 1
                        fi			
                fi
        done
else
        sleep 5
        echo  -e "\n 
	\n
	\n
	\n
	\n
	\n
	${BRed}
					FATAL ERROR
					-----------
	\n
	
	METGRID, not completed${NC}. 
	\n
		
	1. Check for issues in .log_ungrib_* and .log_metgrid  files to know the error source. 
	\n
	2. Check all libraries whether all working fine or not: MPI, WGRIB2, NCKS, ECCODES, NETCDF4\n

	3. Otherwise, contact NCMRWF.
	\n"
fi
rm -rf .success .unsuccess .ungrib_done .imdaa_sorted .geogrid_done .namelist.wps.* .geogrid_error *.log*
