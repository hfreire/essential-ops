#!/bin/sh

EXTENSION=".tar.gz"

# print help
print_help() {
    echo "Usage: $0 <dir1 dir2...> <rotations> <backups dir> <name>"
}

# rotate
rotate() {
	number=$(ls $backups_dir/$name.*$EXTENSION 2>/dev/null | wc -l);

	# no need to rotate
	if [ "$number" -eq 0 ]; then
		echo "No previous backups detected."
		return
	fi

	# delete only 1 previous backup
	if [ "$number" -eq "$rotations" ]; then
		echo "Detected previous backups. Removing oldest one: $name.$number$EXTENSION"
		rm -f $backups_dir/$name.$number$EXTENSION
		number=$(($number-1))
	fi

	# delete all number of backups over the number of rotations
	if [ "$number" -gt "$rotations" ]; then
		over=$(($number-$rotations))
		i=0
		until [ "$i" < "$over" ]; do
			echo "Detected previous backups. Removing oldest one: $name.$number$EXTENSION"
			rm -f $backups_dir/$name.$number$EXTENSION
			number=$(($number-1))
			$(($i+1))
		done
	fi
	echo $number

	number=$(($number+1))
	backups=$(ls -tr $backups_dir/$name.*$EXTENSION);

	for backup in $backups; do
		echo "Renaming $backup to $name.$number$EXTENSION"
		mv -f $backup $backups_dir/$name.$number$EXTENSION
		number=$(($number-1))
	done
}

# package
package() {
	tar -czPhf $name.1$EXTENSION $dirs
	chmod 440 $name.1$EXTENSION
}

# check arguments
if [ "$#" -ne 4 ]; then
        print_help
        exit 1
fi

dirs=$1
rotations=$2

if [ "$4" = "none" ]; then
	backups_dir=$3
	name=backup
else
	backups_dir=$3/$4
	name=$4
fi

cd $backups_dir

rotate
package

exit 0
