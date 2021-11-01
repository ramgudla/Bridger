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

#   sftp -oPreferredAuthentications=password -oPubkeyAuthentication=no BhAiInNeKeTESTOut@69.84.186.61
#   pgZ}6sv=eeV%
#
#  sftp -i id_rsa BhAiInNeKeTESTOut@69.84.186.61

#bridger_inbound.sh:
#  */5 * * * * /home/citibank/bridger/bridger_inbound.sh BhAiInNeKeTESTOut 69.84.186.61 >> /home/citibank/bridger/bridger_inbound.log 2>&1
#                                     bridger_inbound.sh BhAiInNeKeTESTOut 69.84.186.61 >> /home/citibank/bridger/bridger_inbound.log 2>&1

#logrotate:
# mac:
#  command: /usr/local/opt/logrotate/sbin/logrotate /usr/local/etc/logrotate.d/bridger_inbound.conf
#  status:  /usr/local/var/lib/logrotate.status
# linux:
#  crontab: 0 2 * * * /usr/sbin/logrotate /home/citibank/bridger/bridger_inbound.conf
#
#
##################################################################

prepareBatchFile() {
  for remote_folder in "$@"
  do
    #for i in `cat mylist.txt`
    #remote_files=`echo 'ls' | sftp -i id_rsa -oPort=5032 ramakrishna.rao.gudla@oracle.com@130.35.17.133 | grep -v '^sftp>'`
    #echo ‘ls’ | sftp -i id_rsa -oPort=5032 "$user@$server:$remote_folder" > $listfile
    #remote_files=sftp -q "$user@$server:$remote_folder" <<<"ls" | tail -n+2
    #remote_files=$(sftp -q \"$user@$server:$remote_folder\" <<<\"ls\" | grep -v '^sftp>')
    #remote_files=$(cat $listfile | grep -v '^sftp>')
    remote_files=`echo 'ls' | sftp -i id_rsa $user@$server:$remote_folder | grep -v '^sftp>'`
    for i in $remote_files
    do
      remote_file=$remote_folder$i
      # Place the command to upload files in sftp batch file
      if [[ "$remote_file" == *"$DIRECTOR_FILE_PREFIX"* ]]; then
        #get $remote_file $LOCAL_DIRECTOR_DIR+$i
        echo "get \"$remote_file\" \"$LOCAL_DIRECTOR_DIR+$i\"" >> $tempfile
        echo "mv \"$remote_file\" \"$REMOTE_DIRECTOR_ARCHIVE_DIR\"" >> $tempfile
      elif [[ "$remote_file" == *"$VENDOR_FILE_PREFIX"* ]]; then
        #get $remote_file $LOCAL_VENDOR_DIR+$i
        echo "get \"$remote_file\" \"$LOCAL_VENDOR_DIR+$i\"" >> $tempfile
        echo "mv \"$remote_file\" \"$REMOTE_VENDOR_ARCHIVE_DIR\"" >> $tempfile
      else
        echo "$remote_file is neither Director's nor Suppliers's. This file will be ignored and archived."
        ignored=$(( $ignored + 1 ))
      fi
      # Increase the count value for every file found
      count=$(( $count + 1 ))
      filesArray+=($remote_file)
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
    echo $'\n'"$0: No files to download from $server"
    rm -f $tempfile
    echo "`date` User `whoami` exiting the script."
    echo "##################################################################"$'\n'
    exit 1
  fi

  echo $'\n'"Downloading: Found $count file(s) in remote folders to download. Ignored $ignored file(s)."

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

}

#### main function ####
echo "`date` User `whoami` started the script."

if [ $# -eq 0 ] ; then
  echo "Usage: $0 user host"$'\n' >&2
  exit 1
fi

# Create SFTP batch file
tempfile="/tmp/cmdfile.$$"

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
LOCAL_DIRECTOR_DIR='/home/citibank/bridger/in/director/'
REMOTE_DIRECTOR_DIR='/BridgerStagingOut/AirtelDirectorAutobatch/'

# Vendor local and remote dir
VENDOR_FILE_PREFIX='ASI_Supplier'
LOCAL_VENDOR_DIR='/home/citibank/bridger/in/vendor/'
REMOTE_VENDOR_DIR='/BridgerStagingOut/AirtelVendorAutobatch/'

# Archive files will be moved to this dir
REMOTE_DIRECTOR_ARCHIVE_DIR=$REMOTE_DIRECTOR_DIR'archive'
REMOTE_VENDOR_ARCHIVE_DIR=$REMOTE_VENDOR_DIR'archive'

# Private key file path
KEY_FILE_PATH="/home/citibank/bridger/id_rsa"

prepareBatchFile $REMOTE_DIRECTOR_DIR $REMOTE_VENDOR_DIR

processAndArchiveBatch

# Remove the sftp batch file
rm -f $tempfile

echo "`date` User `whoami` exiting the script."
echo "##################################################################"$'\n'
exit 0
