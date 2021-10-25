#!/bin/bash

#
# Description:
# Get user, remote server, source directory with absolute path details
# as input to sync the latest added files with remote server
#

# Use batch file with SFTP shell script without prompting password
# using SFTP authorized_keys

#sftp commands:
#   ssh-keygen -t rsa -m PEM -f ~/Desktop/Bugs/sftptest/id_rsa
#
#   sftp -oPreferredAuthentications=password -oPubkeyAuthentication=no BhAiInNeKeTEST@69.84.186.61
#   -[C+0kR5d1k
#
#  sftp -i id_rsa BhAiInNeKeTEST@69.84.186.61

#bridger.sh:
#  */5 * * * * /home/citibank/bridger/bridger.sh BhAiInNeKeTEST 69.84.186.61 >> /home/citibank/bridger/bridger.log 2>&1
#                                     bridger.sh BhAiInNeKeTEST 69.84.186.61 >> /home/citibank/bridger/bridger.log 2>&1

#logrotate:
#  /usr/local/opt/logrotate/sbin/logrotate /usr/local/etc/logrotate.d/bridger.conf
#  0 2 * * * root /usr/sbin/logrotate /home/citibank/bridger/bridger.conf
#
#
##################################################################

processFiles() {
  source_dir=${1}
  timestamp="$source_dir/.timestamp"
  # timestamp file will not be available when executed for the very first time
  if [ ! -f $timestamp ] ; then
    # no timestamp file, upload all files
    for filename in $source_dir/*
    do
      if [ -f "$filename" ] ; then
        # Place the command to upload files in sftp batch file
        if [[ "$filename" == *"$DIRECTOR_FILE_PREFIX"* ]]; then
          echo "put -P \"$filename\" \"$TARGET_DIRECTOR_DIR\"" >> $tempfile
        elif [[ "$filename" == *"$VENDOR_FILE_PREFIX"* ]]; then
          echo "put -P \"$filename\" \"$TARGET_VENDOR_DIR\"" >> $tempfile
        else
          echo "$filename is neither Director's nor Vendor's. Didn't upload to Bridger!"
          ignored=$(( $ignored + 1 ))
        fi
        # Increase the count value for every file found
        count=$(( $count + 1 ))
        filesArray+=($filename)
      fi
    done
  else
    # If timestamp file found then it means it is not the first execution so look out for newer files only
    # Check for newer files based on the timestamp
    for filename in $(find $source_dir -newer $timestamp -type f -print)
    do
      # Place the command to upload files in sftp batch file
      if [[ "$filename" == *"$DIRECTOR_FILE_PREFIX"* ]]; then
        echo "put -P \"$filename\" \"$TARGET_DIRECTOR_DIR\"" >> $tempfile
      elif [[ "$filename" == *"$VENDOR_FILE_PREFIX"* ]]; then
        echo "put -P \"$filename\" \"$TARGET_VENDOR_DIR\"" >> $tempfile
      else
        echo "$filename is neither Director's nor Vendor's. Didn't upload to Bridger!"
        ignored=$(( $ignored + 1 ))
      fi
      # Increase the count based on the new files
      count=$(( $count + 1 ))
      filesArray+=($filename)
    done
  fi
}

syncAndArchiveFiles() {
  # Place the command to exit the sftp connection in batch file
  echo "quit" >> $tempfile

  echo "SFTP Commands to execute:"
  cat $tempfile

  # If no new files found then do nothing
  if [ $count -eq 0 ] ; then
    echo "$0: No files require uploading to $server"
    echo "Removing tempfile: $tempfile"
    rm -f $tempfile
    echo "`date` User `whoami` exiting the script."$'\n'
    exit 1
  fi

  echo "Synchronizing: Found $count file(s) in local folder to upload. Ignored $ignored file(s)."

  # Main command to use batch file with SFTP shell script without prompting password
  #sftp -i $KEY_FILE_PATH -b $tempfile -oPort=22 "$user@$server"

  if [ $? -ne 0 ] ; then
    echo "sftp command failed..."
    echo "Removing tempfile: $tempfile"
    rm -f $tempfile
    echo "`date` User `whoami` exiting the script."$'\n'
    exit 1
  fi
  echo "Done. All files synchronized up with $server"$'\n'

  archiveFiles
}

archiveFiles() {
  # Move all the files to processed folder
  echo "Archiving ${filesArray[@]} to respective archive folders..."
  for value in "${filesArray[@]}"
  do
    if [[ "$value" == *"$DIRECTOR_FILE_PREFIX"* ]]; then
      mv $value $DIRECTOR_ARCHIVE_DIR
    else
      mv $value $VENDOR_ARCHIVE_DIR
    fi
  done
}

touchTimestamps() {
  # Create timestamp file once first set of files are uploaded
  source_dir=${1}
  timestamp="$source_dir/.timestamp"
  touch $timestamp
}


#### main function ####

echo "`date` User `whoami` started the script."

if [ $# -eq 0 ] ; then
  echo "Usage: $0 user host"$'\n' >&2
  exit 1
fi

# Create SFTP batch file
tempfile="/tmp/bridger.$$"

# initialize counters
count=0
ignored=0
filesArray=()

trap "/bin/rm -f $tempfile" 0 1 15

# Collect User Input
user="$1"
server="$2"

# Director source and target dir
DIRECTOR_FILE_PREFIX='ASI_Director'
SRC_DIRECTOR_DIR='/home/citibank/bridger/out/director'
TARGET_DIRECTOR_DIR='/BridgerRefactor-Staging/AirtelDirectorAutobatch'

#SRC_DIRECTOR_DIR='/Users/ramgudla/Desktop/Bugs/sftptest/director'

# Vendor source target dir
VENDOR_FILE_PREFIX='ASI_Supplier'
SRC_VENDOR_DIR='/home/citibank/bridger/out/vendor'
TARGET_VENDOR_DIR='/BridgerRefactor-Staging/AirtelVendorAutobatch'

#SRC_VENDOR_DIR='/Users/ramgudla/Desktop/Bugs/sftptest/vendor'

# Archive files will be moved to this dir
DIRECTOR_ARCHIVE_DIR='/home/citibank/bridger/out/director/archive'
VENDOR_ARCHIVE_DIR='/home/citibank/bridger/out/vendor/archive'

#DIRECTOR_ARCHIVE_DIR='/Users/ramgudla/Desktop/Bugs/sftptest/director/archive'
#VENDOR_ARCHIVE_DIR='/Users/ramgudla/Desktop/Bugs/sftptest/vendor/archive'

# Private key file path
KEY_FILE_PATH="/home/citibank/bridger/id_rsa"

processFiles $SRC_DIRECTOR_DIR
processFiles $SRC_VENDOR_DIR

syncAndArchiveFiles

touchTimestamps $SRC_DIRECTOR_DIR
touchTimestamps $SRC_VENDOR_DIR

# Remove the sftp batch file
echo "Removing tempfile: $tempfile"
rm -f $tempfile

echo "`date` User `whoami` exiting the script."$'\n'
exit 0
