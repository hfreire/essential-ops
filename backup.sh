#!/bin/sh

EXTENSION="tar.gz"
DATE_FORMAT=$(date +%Y-%m-%d)

# print help
print_help() {
    echo "Usage: $0 -s <dir1 dir2...> -d <backups dir> -n <name> -r <number of rotations>"
}

# rotate backups by date
rotate_backups() {
    local destination="$1"
    local name="$2"
    local rotations="$3"
    local total=$(ls $destination/$name.*$EXTENSION 2>/dev/null | wc -l | sed -e 's/^[ \t]*//');

    # no need to rotate
    if [ "$total" -eq 0 ]; then
        echo "No existent backups detected."
        return
    fi

    if [ "$total" -eq "$rotations" ]; then # remove the oldest backup
        backup=$(ls $destination/$name.*$EXTENSION 2>/dev/null | head -n 1 | sed 's,^[^ ]*/,,')
        echo "Removing backup $destination/$backup"
        rm -f $destination/$backup
        total=$(($total-1))
    elif [ "$total" -gt "$rotations" ]; then # remove all number of backups over the number of rotations
        over=$(($total-$rotations))
        i=1
        until [ "$over" -lt "$i" ]; do
            backup=$(ls $destination/$name.*$EXTENSION 2>/dev/null | head -n 1 | sed 's,^[^ ]*/,,')
            echo "Removing $destination/$backup"
            rm -f $destination/$backup
            total=$(($total-1))
            i=$(($i+1))
        done
    fi
}

# backup filesystem
backup_filesystem() {
    local sources="$1"
    local name="$2"
    local destination="$3"

    echo "Backing up $sources into $destination/$name.$DATE_FORMAT.$EXTENSION"
    rm -f $destination/$name.$DATE_FORMAT.$EXTENSION
    GZIP="-9 --rsyncable" tar -czPhf $destination/$name.$DATE_FORMAT.$EXTENSION $sources
    chmod 440 $destination/$name.$DATE_FORMAT.$EXTENSION
}

while getopts ":s:d:r:n:i:" opt; do
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

[ -n "$sources" ] &&
[ -n "$destination" ] &&
[ -n "$rotations" ]  &&
[ -n "$name" ] || { print_help; exit 1; }

rotate_backups "$destination" "$name" "$rotations"
backup_filesystem "$sources" "$name" "$destination"

exit 0
