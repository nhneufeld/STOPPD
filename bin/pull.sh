#!/bin/bash
# Fetch newest scans from the MRFTP server
host=STOP@mr-ftp
outputdir=data/zips/CMH

echo "Copying new scans..."
sftp -b- $host <<EOF
get -a STOP*MR/* $outputdir/
EOF
if [[ $? -ne 0 ]]; then
  echo "Error downloading new scans... Quitting."
  exit 1;
fi
