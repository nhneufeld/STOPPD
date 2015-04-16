#!/bin/bash
# Runs all the pipelines!

PROJECTDIR=/archive/data-2.0/STOPPD
DATESTAMP=$(date +%Y%m%d)
source $PROJECTDIR/bin/env.sh

{ 
  cd $PROJECTDIR

  echo "Get new scans..."
  pull.sh 

  echo "Link scans..."
  link.sh

  echo "Uploading new scans to XNAT..."
  upload.sh

  echo "Extract new scans from XNAT..."
  extract.sh

  echo "Generating QC documents..."
  qc.sh

  echo "Running dtifit..."
  dm-proc-dtifit.py

  echo "Done."
} | tee -a logs/run-all-${DATESTAMP}.log
