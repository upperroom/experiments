#!/bin/sh
#########################################################
###
##  File: bad_links_report.sh
##  Desc: Produce the bad links report from a site sucker error log file
#

# Input file
site_sucker_log='UpperRoomDotORG.suck.log'

if [[ ! -f $site_sucker_log ]]; then
  echo "ERROR: File does not exist."
  echo "       $site_sucker_log"
  exit -1
fi

# Temporaru files
error_log='error.log'
bad_links_log='bad_links.log'

# Output file
bad_links_report='bad_links_report.txt'

# Programs
extract_errors_from_log='extract_errors_from_log.rb'
invert_log_file='invert_log_file.rb'

if [[ ! -f $extract_errors_from_log ]]; then
  echo "ERROR: File does not exist."
  echo "       $extract_errors_from_log"
  exit -2
fi

if [[ ! -f $invert_log_file ]]; then
  echo "ERROR: File does not exist."
  echo "       $invert_log_file"
  exit -3
fi




echo
echo "Extract errors from $site_sucker_log ..."
ruby $extract_errors_from_log $site_sucker_log > $error_log

fgrep 'does not exist' $error_log      > $bad_links_log
fgrep 'could not be found' $error_log >> $bad_links_log

echo "Extracting and inverting fields for report ..."
ruby $invert_log_file $bad_links_log | sort - > $bad_links_report

rm -fr $error_log $bad_links_log

echo
echo "Bad Links Report: $bad_links_report"
echo "     Error Count: `wc -l $bad_links_report | cut -c 1-8`"
echo

