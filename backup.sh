#!/bin/sh
EXTENSION="tar.gz"

# print help
print_help() {
    echo "Usage: $0 -s <sources> -d <backup directory> -n <name> -r <retention> [-y]"
}

# rotate
remove_backups() {
    local destination="$1"
    local name="$2"
    local date="$3"
    local retention="$4"
    local backups=$(ls $destination/$name.*.$EXTENSION 2>/dev/null | wc -l | sed -e 's/^[ \t]*//');

    if [ ! -f "$destination/$name.$date.$EXTENSION" ]; then
        $retention=$(($4-1));
    fi

    if [ "$backups" -gt "$retention" ]; then
        for backup in $(ls $destination/$name.*.$EXTENSION 2>/dev/null); do
            echo "Removing backup $backup"
            rm -f $backup;
            backups=$(($backups-1))
            if [ "$backups" -le "$retention" ]; then
                break;
            fi
        done
    fi
}

# backup filesystem
backup_filesystem() {
    local sources="$1"
    local name="$2"
    local date="$3"
    local destination="$4"

    echo "Backing up $sources into $destination/$name.$date.$EXTENSION"
    GZIP="-9 --rsyncable" tar -czPhf $destination/$name.$date.$EXTENSION $sources
    chmod 440 $destination/$name.$date.$EXTENSION
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
        retention=$OPTARG
        ;;
    n)
        name=$OPTARG
        ;;
    y)
        yesterday=true
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        ;;
  esac
done

[ -n "$sources" ] &&
[ -n "$destination" ] &&
[ -n "$retention" ]  &&
[ -n "$name" ] || { print_help; exit 1; }

if [ -n "$yesterday" ] && [ $yesterday ]; then
    date=$(date -d "yesterday" '+%Y-%m-%d')
else
    date=$(date +%Y-%m-%d)
fi

remove_backups "$destination" "$name" "$date" "$retention"
backup_filesystem "$sources" "$name" "$date" "$destination"

exit 0
