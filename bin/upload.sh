#!/bin/bash
# Upload to XNAT
XNAT_STUDYID=STOPPD01
XNAT_ARCHIVE=/mnt/xnat/spred/archive/${XNAT_STUDYID}/arc001
DICOM_ZIPS=/archive/data-2.0/STOPPD/data/dicom/*_CMH_*.zip
CREDFILE=metadata/xnat-credentials

for zip in ${DICOM_ZIPS}; do 
  scanid=$(basename $zip .zip)
  if [ -e ${XNAT_ARCHIVE}/${scanid} ]; then 
    continue
  fi
  echo xnat-upload.py -v --credfile ${CREDFILE} ${XNAT_STUDYID} ${zip} 
done
