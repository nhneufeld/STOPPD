#!/bin/bash
# Extracts archived scans from XNAT into this folder
#
set -e

XNAT_ARCHIVE=/mnt/xnat/spred/archive
CMH_ARCHIVE=${XNAT_ARCHIVE}/STOPPD01/arc001
MAS_ARCHIVE=${XNAT_ARCHIVE}/STOPPD02/arc001
NKI_ARCHIVE=${XNAT_ARCHIVE}/STOPPD03/arc001
PMC_ARCHIVE=${XNAT_ARCHIVE}/STOPPD04/arc001
DATESTAMP=$(date +%Y%m%d)
o=""

{
echo 
echo "----------------------------------------"
echo "Starting export on $(date)              " 
echo "----------------------------------------"

echo "Exporting CMH site archives..."
xnat-extract.py $o --exportinfo metadata/exportinfo-CMH.csv ${CMH_ARCHIVE}/* 

echo "Exporting MAS site archives..."
xnat-extract.py $o --exportinfo metadata/exportinfo-MAS.csv ${MAS_ARCHIVE}/* 

echo "Exporting NKI site archives..."
xnat-extract.py $o --exportinfo metadata/exportinfo-NKI.csv ${NKI_ARCHIVE}/* 

echo "Exporting PMC site archives..."
xnat-extract.py $o --exportinfo metadata/exportinfo-PMC.csv ${PMC_ARCHIVE}/* 

} | tee -a logs/extract-$DATESTAMP.log
