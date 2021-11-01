#!/bin/bash

#
# Description:
# Get user, remote server, source directory with absolute path details
# as input to sync the latest added files with remote server
#

# Use batch file with SFTP shell script without prompting password
# using SFTP authorized_keys

#sftp commands:
#   ssh-keygen -t rsa -m PEM -f /home/citibank/bridger/id_rsa
#
#   sftp -oPreferredAuthentications=password -oPubkeyAuthentication=no BhAiInNeKeTEST@69.84.186.61
#   -[C+0kR5d1k

#
#  sftp -i id_rsa BhAiInNeKeTEST@69.84.186.61

#bridger_outbound.sh:
#  */5 * * * * /home/citibank/bridger/bridger_outbound.sh BhAiInNeKeTEST 69.84.186.61 >> /home/citibank/bridger/bridger_outbound.log 2>&1
#                                     bridger_outbound.sh BhAiInNeKeTEST 69.84.186.61 >> /home/citibank/bridger/out/bridger_outbound.log 2>&1

#logrotate:
# mac:
#  command: /usr/local/opt/logrotate/sbin/logrotate /usr/local/etc/logrotate.d/bridger_outbound.conf
#  status:  /usr/local/var/lib/logrotate.status
# linux:
#  crontab: 0 2 * * * /usr/sbin/logrotate /home/citibank/bridger/bridger_outbound.conf
#
#
##################################################################

prepareBatchFile() {
  for folder in "$@"
  do
    echo $'\n'"Collecting files from the folder: $folder"
    for filename in $folder/*
    do
      if [ -f "$filename" ] ; then
        # Place the command to upload files in sftp batch file
        if [[ "$filename" == *"$DIRECTOR_FILE_PREFIX"* ]]; then
          echo "$filename"
          echo "put -P \"$filename\" \"$REMOTE_DIRECTOR_DIR\"" >> $tempfile
        elif [[ "$filename" == *"$VENDOR_FILE_PREFIX"* ]]; then
          echo "$filename"
          echo "put -P \"$filename\" \"$REMOTE_VENDOR_DIR\"" >> $tempfile
        else
          echo "$filename is neither Director's nor Suppliers's. This file will be ignored and archived."
          ignored=$(( $ignored + 1 ))
        fi
        # Increase the count value for every file found
        count=$(( $count + 1 ))
        filesArray+=($filename)
      fi
    done
  done

  # Place the command to exit the sftp connection in batch file
  echo "quit" >> $tempfile

  echo $'\n'"SFTP Commands to execute:"
  cat $tempfile
}

processAndArchiveBatch() {
  # If no new files found then do nothing
  if [ $count -eq 0 ] ; then
    echo $'\n'"$0: No files require uploading to $server"
    rm -f $tempfile
    echo "`date` User `whoami` exiting the script."
    echo "##################################################################"$'\n'
    exit 1
  fi

  echo $'\n'"Synchronizing: Found $count file(s) in local folder to upload. Ignored $ignored file(s)."

  # Main command to use batch file with SFTP shell script without prompting password
  sftp -i $KEY_FILE_PATH -b $tempfile -oPort=22 "$user@$server"

  if [ $? -ne 0 ] ; then
    echo "sftp command failed..."
    rm -f $tempfile
    echo "`date` User `whoami` exiting the script."
    echo "##################################################################"$'\n'
    exit 1
  fi
  echo "Done. All files synchronized up with $server"$'\n'

  archiveFiles
}

archiveFiles() {
  # Move all the files to processed folder
  echo "Archiving ${filesArray[@]} to respective archive folders..."$'\n'
  for value in "${filesArray[@]}"
  do
    if [[ "$value" == *"$DIRECTOR_FILE_PREFIX"* ]]; then
      mv $value $LOCAL_DIRECTOR_ARCHIVE_DIR
    else
      mv $value $LOCAL_VENDOR_ARCHIVE_DIR
    fi
  done
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

# Director local and remote dir
DIRECTOR_FILE_PREFIX='ASI_Director'
LOCAL_DIRECTOR_DIR='/home/citibank/bridger/out/director'
REMOTE_DIRECTOR_DIR='/BridgerRefactor-Staging/AirtelDirectorAutobatch'

# Vendor local and remote dir
VENDOR_FILE_PREFIX='ASI_Supplier'
LOCAL_VENDOR_DIR='/home/citibank/bridger/out/vendor'
REMOTE_VENDOR_DIR='/BridgerRefactor-Staging/AirtelVendorAutobatch'

# Archive files will be moved to this dir
LOCAL_DIRECTOR_ARCHIVE_DIR=$LOCAL_DIRECTOR_DIR'/archive'
LOCAL_VENDOR_ARCHIVE_DIR=$LOCAL_VENDOR_DIR'/archive'

# Private key file path
KEY_FILE_PATH="/home/citibank/bridger/id_rsa"

###################### Testing ################################################
#LOCAL_DIRECTOR_DIR='/Users/ramgudla/Desktop/Bugs/sftptest/director'
#LOCAL_VENDOR_DIR='/Users/ramgudla/Desktop/Bugs/sftptest/vendor'
#LOCAL_DIRECTOR_ARCHIVE_DIR='/Users/ramgudla/Desktop/Bugs/sftptest/director/archive'
#LOCAL_VENDOR_ARCHIVE_DIR='/Users/ramgudla/Desktop/Bugs/sftptest/vendor/archive'
###################### Testing ################################################

prepareBatchFile $LOCAL_DIRECTOR_DIR $LOCAL_VENDOR_DIR

processAndArchiveBatch

# Remove the sftp batch file
rm -f $tempfile

echo "`date` User `whoami` exiting the script."
echo "##################################################################"$'\n'
exit 0
