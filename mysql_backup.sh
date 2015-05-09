#!/bin/sh
EXTENSION="tar.xz"

MYSQL_BIN=$(which mysql)
MYSQLDUMP_BIN=$(which mysqldump)
TAR_BIN=$(which tar)

# print help
print_help() {
    echo "Usage: $0 -u <mysql_user> -p <mysql_password> -h <mysql_host> -d <backups dir> -n <name> -r <number of retention>"
}

# remove backups
remove_backups() {
    local destination="$1"
    local name="$2"
    local date="$3"
    local retention="$4"
    local backups=$(ls $destination/$name.*.$EXTENSION 2>/dev/null | wc -l | sed -e 's/^[ \t]*//');

    if [ ! -f "$destination/$name.$date.$EXTENSION" ]; then
        retention=$(($4-1));
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
    XZ_OPT="-9e" $TAR_BIN -cJPhf $destination/$name.$date.$EXTENSION $sources
    chmod 440 $destination/$name.$date.$EXTENSION
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
        $MYSQLDUMP_BIN -u $user -p$password -h $host --hex-blob --routines --triggers $database --max_allowed_packet=128M > $destination/tables/$database.sql &
    done
    wait
}

create_symlink() {
    local destination="$1"
    local name="$2"
    local date="$3"

    cd $destination
    rm $name.$EXTENSION
    ln -s $name.$date.$EXTENSION $name.$EXTENSION
}

while getopts ":u:p:h:d:n:r:y:l:" opt; do
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
        retention=$OPTARG
        ;;
    y)
        yesterday=true
        ;;
    l)
        symlink=true
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
[ -n "$retention" ] ||
{ print_help; exit 1; }

if [ -n "$yesterday" ]; then
    date=$(date -d "yesterday" '+%Y-%m-%d')
else
    date=$(date +%Y-%m-%d)
fi

remove_backups "$destination" "$name" "$date" "$retention"
mkdir -p $destination/$name/tables
backup_mysql "$user" "$password" "$host" "$destination/$name"
backup_filesystem "$destination/$name" "$name" "$date" "$destination"
rm -rf $destination/$name
$symlink && create_symlink "$destination" "$name" "$date"

exit 0
