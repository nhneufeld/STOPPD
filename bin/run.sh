#!/bin/bash --login
# Runs pipelines like a bro
#
# Usage:
#   run.sh [options]
#
# Options:
#   --quiet     Don't be chatty (doesn't apply to pipeline stages)
#               
#

STUDYNAME=STOPPD      # Data archive study name
XNAT_PROJECT=STOPPD01 # XNAT project name
MRUSER=STOPPD01       # MR Unit FTP user
PROJECTDIR=/archive/data-2.0/${STUDYNAME}
XNAT_ARCHIVE_CMH=/mnt/xnat/spred/archive/STOPPD01/arc001
XNAT_ARCHIVE_MAS=/mnt/xnat/spred/archive/STOPPD02/arc001
XNAT_ARCHIVE_NKI=/mnt/xnat/spred/archive/STOPPD03/arc001
XNAT_ARCHIVE_PMC=/mnt/xnat/spred/archive/STOPPD04/arc001
CMH_STANDARD=${PROJECTDIR}/gold_standards/CMH
MAS_STANDARD=${PROJECTDIR}/gold_standards/MAS
NKI_STANDARD=${PROJECTDIR}/gold_standards/NKI
PMC_STANDARD=${PROJECTDIR}/gold_standards/PMC

args="$@"                           # commence ugly opt handling
DATESTAMP=$(date +%Y%m%d)

module load /archive/data-2.0/code/datman.module
export PATH=$PATH:${PROJECTDIR}/bin

function message () { [[ "$args" =~ "--quiet" ]] || echo "$(date): $1"; }

{
  message "Running pipelines for study: $STUDYNAME"

  message "Get new scans..."
  dm-sftp-sync.sh ${MRUSER}@mrftp.camphpet.ca "${MRUSER}*MR/*" ${PROJECTDIR}/data/zips

  message "Link scans..."
  link.py \
    --lookup=${PROJECTDIR}/metadata/scans.csv \
    ${PROJECTDIR}/data/dicom/ \
    ${PROJECTDIR}/data/zips/*.zip

  message "Uploading new scans to XNAT..."
  dm-xnat-upload.sh \
    ${XNAT_PROJECT} \
    ${XNAT_ARCHIVE_CMH} \
    ${PROJECTDIR}/data/dicom \
    ${PROJECTDIR}/metadata/xnat-credentials

  message "Extract new scans from XNAT..."
  module load slicer/4.4.0 mricron/0.20140804 minc-toolkit/1.0.01
  xnat-extract.py \
    --blacklist ${PROJECTDIR}/metadata/blacklist.csv \
    --datadir ${PROJECTDIR}/data \
    --exportinfo ${PROJECTDIR}/metadata/exportinfo-CMH.csv \
    ${XNAT_ARCHIVE_CMH}/*

  xnat-extract.py \
    --blacklist ${PROJECTDIR}/metadata/blacklist.csv \
    --datadir ${PROJECTDIR}/data \
    --exportinfo ${PROJECTDIR}/metadata/exportinfo-MAS.csv \
    ${XNAT_ARCHIVE_MAS}/*

  xnat-extract.py \
    --blacklist ${PROJECTDIR}/metadata/blacklist.csv \
    --datadir ${PROJECTDIR}/data \
    --exportinfo ${PROJECTDIR}/metadata/exportinfo-NKI.csv \
    ${XNAT_ARCHIVE_NKI}/*

  xnat-extract.py \
    --blacklist ${PROJECTDIR}/metadata/blacklist.csv \
    --datadir ${PROJECTDIR}/data \
    --exportinfo ${PROJECTDIR}/metadata/exportinfo-PMC.csv \
    ${XNAT_ARCHIVE_PMC}/*

  module unload slicer/4.4.0 mricron/0.20140804 minc-toolkit/1.0.01

  message "Checking DICOM headers... "
  dm-check-headers.py ${CMH_STANDARD} ${PROJECTDIR}/dcm/SPN01_CMH_*
  #dm-check-headers.py ${MAS_STANDARD} ${PROJECTDIR}/dcm/SPN01_MAS_*
  #dm-check-headers.py ${NKI_STANDARD} ${PROJECTDIR}/dcm/SPN01_NKI_*
  #dm-check-headers.py ${PMC_STANDARD} ${PROJECTDIR}/dcm/SPN01_PMC_*

  message "Checking gradient directions..."
  dm-check-bvecs.py \
    ${PROJECTDIR} ${PROJECTDIR}/metadata/gold_standards/CMH/ CMH

  message "Split the PDT2 images..."
  (module load FSL/5.0.7
   dm-proc-split-pdt2.py data/nii/*/*_PDT2_*.nii.gz
  )

  message "Generating QC documents..."
  (module load AFNI/2014.12.16 FSL/5.0.7 matlab/R2013b_concurrent
  qc.py --datadir ${PROJECTDIR}/data/ --qcdir ${PROJECTDIR}/qc
  )

  message "Updating QC checklist..."
  qc-report.py ${PROJECTDIR}

  message "Pushing QC documents to github..."
  ( # subshell invoked to handle directory change
    cd ${PROJECTDIR}
    git add qc/
    git add metadata/checklist.csv
    git diff --quiet HEAD || git commit -m "Autoupdating QC documents"
    git push  # --quiet for quietness
  ) 

  message "Running freesurfer..."
  dm-proc-freesurfer.py ${PROJECTDIR}


  message "Running resting state analysis..."
  dm-proc-rest.py \
    ${PROJECTDIR} \
    /scratch/clevis/ \
    /archive/data-2.0/code/datman/assets/150409-compcor-nonlin-8fwhm.sh

  message "Running dtifit..."
  module load FSL/5.0.7
  dm-proc-dtifit.py \
    --datadir ${PROJECTDIR}/data/ \
    --outputdir ${PROJECTDIR}/data/dtifit
  module unload FSL/5.0.7

  message "Done."
} | tee -a ${PROJECTDIR}/logs/run-all-${DATESTAMP}.log

