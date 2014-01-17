#!/bin/sh
EXTENSION=".tar.gz"

# print help
print_help() {
    echo "Usage: $0 -s <dir1 dir2...> -d <backups dir> -n <name> -r <number of rotations>"
}

# rotate
rotate_backups() {
    local destination=$1
    local name=$2
    local rotations=$3
	local number=$(ls $destination/$name.*$EXTENSION 2>/dev/null | wc -l | sed -e 's/^[ \t]*//');

	# no need to rotate
	if [ "$number" -eq 0 ]; then
		echo "No existent backups detected."
		return
	fi

	# remove the oldest backup
	if [ "$number" -eq "$rotations" ]; then
		echo "Removing backup $destination/$name.$number$EXTENSION"
		rm -f $destination/$name.$number$EXTENSION
		number=$(($number-1))
	fi

	# remove all number of backups over the number of rotations
	if [ "$number" -gt "$rotations" ]; then
		over=$(($number-$rotations))
		i=0
		until [ "$i" < "$over" ]; do
			echo "Removing $destination/$name.$number$EXTENSION"
			rm -f $destination/$name.$number$EXTENSION
			number=$(($number-1))
			$(($i+1))
		done
	fi

	number=$(($number+1))

	for backup in $(ls -tr $destination/$name.*$EXTENSION 2>/dev/null); do
		echo "Renaming $backup to $name.$number$EXTENSION"
		mv -f $backup $destination/$name.$number$EXTENSION
		number=$(($number-1))
	done
}

# backup filesystem
backup_filesystem() {
    local sources=$1
    local name=$2
    local destination=$3

    echo "Backing up $sources into $destination/$name.1$EXTENSION"
	tar -czPhf $destination/$name.1$EXTENSION $sources
	chmod 440 $destination/$name.1$EXTENSION
}

while getopts ":s:d:r:n:" opt; do
  case $opt in
    s)
        sources=$OPTARG
        ;;
    d)
        destination=$OPTARG
        ;;
    r)
        rotations=$OPTARG
        ;;
    n)
        name=$OPTARG
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        ;;
  esac
done

[[ -n "$sources" ]] &&
[[ -n "$destination" ]] &&
[[ -n "$rotations" ]]  &&
[[ -n "$name" ]] || { print_help; exit 1; }

rotate_backups "$destination" "$name" "$rotations"
backup_filesystem "$sources" "$name" "$destination"

exit 0
