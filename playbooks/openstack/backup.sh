#!/bin/bash
#
#This script is used for backend server volume's backup. This script will take two 
# arguments; a UUID of the backup server and the number of old snapshots to keep.
#Usage:  ./backup.sh <UUID-of-the-backup-server> <number-of-old-snapshots-to-keep>
#Example: ./backup.sh ebddcc34-8c4b-40e6-8f3c-6fe7114079c3 2
#In this example the backup script will take snapshots of the mysql and mongodb volumes
#attached to the ebddcc34-8c4b-40e6-8f3c-6fe7114079c3 server. Only two old snapshots 
#will be spared and rest of the old snapshots will be deleted.

if [ $# -ne 2 ]; then
    echo "$0: usage: ./backup.sh <UUID-of-the-backup-server> <number-of-old-snapshots-to-keep>"
    exit 1
fi

UUID=$1
SNAPS=$2

# The current date will be appended to the snapshot names
DATETIME=$(date +"%Y%m%d-%H%M%S")

# Delete a volume type's old snapshots for this instance
delete_snapshots () {
  vtype=$1
  snaps=$(cinder snapshot-list --status available | awk -F' *\| *' -v i=$vtype-$UUID '$5~i {print $5 " " $2}' | sort | awk '{print $2}')
  set -- $snaps
  while [ $# -ge $SNAPS ]; do
    cinder snapshot-delete $1
    shift
  done
}

# Create a snapshot for an instance's volume type
create_snapshot () {
  vtype=$1
  vid=$(cinder list --status in-use | awk -F' *\| *' -v i=$UUID -v j=$vtype '$8==i && $4~j {print $2}')
  [ -z "$vid"] && return 1
  cinder snapshot-create --force True --display-name $vtype-$UUID-$DATETIME $vid
}

for i in mysql_data mongodb_data; do
  delete_snapshots $i && create_snapshot $i
done
