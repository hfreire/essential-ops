#!/bin/sh
EXTENSION=".tar.gz"

MYSQL_BIN=$(which mysql)
MYSQLDUMP_BIN=$(which mysqldump)

# print help
print_help() {
    echo "Usage: $0 -u <mysql_user> -p <mysql_password> -h <mysql_host> -d <backups dir> -n <name> -r <number of rotations>"
}

# rotate backups
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

backup_filesystem() {
    local sources=$1
    local name=$2
    local destination=$3

    echo "Backing up $sources into $destination/$name.1$EXTENSION"
    tar -czPhf $destination/$name.1$EXTENSION $sources
    chmod 440 $destination/$name.1$EXTENSION
}

# backup mysql
backup_mysql() {
    local user=$1
    local password=$2
    local host=$3
    local destination=$4

    databases=$($MYSQL_BIN -u $user -p$password -h $host -A --skip-column-names -e"SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ('information_schema','mysql', 'performance_schema', 'innodb', 'tmp')")

    for database in $databases
    do
        $MYSQLDUMP_BIN -u $user -p$password -h $host --hex-blob --routines --triggers $database --max_allowed_packet=128M | gzip > $destination/tables/$database.sql.gz &
    done
    wait
}

while getopts ":u:p:h:d:n:r:" opt; do
  case $opt in
    u)
        user=$OPTARG
        ;;
    p)
        password=$OPTARG
        ;;
    h)
        host=$OPTARG
        ;;
    d)
        destination=$OPTARG
        ;;
    n)
        name=$OPTARG
        ;;
    r)
        rotations=$OPTARG
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        ;;
  esac
done

[ -n "$user" ] &&
[ -n "$password" ] &&
[ -n "$host" ]  &&
[ -n "$destination" ]  &&
[ -n "$name" ]  &&
[ -n "$rotations" ] ||
{ print_help; exit 1; }

rotate_backups "$destination" "$name" "$rotations"

mkdir -p $destination/$name/tables
backup_mysql "$user" "$password" "$host" "$destination/$name"
backup_filesystem "$destination/$name" "$name" "$destination"
rm -rf $destination/$name

exit 0
