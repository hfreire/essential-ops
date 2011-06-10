#!/bin/sh
#
# @name backup.sh
# @version 0.2.2
# @args $1 = source directory, $2 = destiny directory, $3 = backup name
# @description
# @author Hugo Freire <hugo.freire@t-creator.pt>

RSYNC_OPTS="-ahAX --delete --force --ignore-errors"
RSYNC_EXCLUDES="--exclude dev --exclude backups --exclude cache --exclude run --exclude lock --exclude tmp --exclude spool --exclude amavisd.sock"
TMP="temp"
EXTENSION=".tar.gz"
ROTATIONS=7

# print help
print_help() {
    echo "Usage: $0 SRC DEST NAME"
}

# archive
function archive() {
	if [ -e $DEST/$NAME.1$EXTENSION ]; then
		tar -zxf $DEST/$NAME.1$EXTENSION -C $TMP
	fi
	
	rsync $RSYNC_OPTS $SRC $TMP $RSYNC_EXCLUDES
}

# rotate
function rotate() {
	number=$(ls $DEST/$NAME.*$EXTENSION 2>/dev/null | wc -l);

	if [ "$number" -eq 0 ]; then
		return # no need to rotate
	fi
	
	if [ "$number" -eq "$ROTATIONS" ]; then
		rm -f $DEST/$NAME.$number$EXTENSION
		number=$(($number-1))
	fi
	
	if [ "$number" -gt "$ROTATIONS" ]; then
		over=$(($number-$ROTATIONS))
		for((i=0; $i<=$over;i=$(($i+1)))); do
			rm -f $DEST/$NAME.$number$EXTENSION
			number=$(($number-1))
		done	
	fi	
	
	number=$(($number+1))
	backups=$(ls -r $DEST/$NAME.*$EXTENSION);

	for backup in $backups; do
		mv -f $backup $DEST/$NAME.$number$EXTENSION
		number=$(($number-1))
	done
}

# package
function package() {
	cd $TMP
	tar -zcf $NAME.1$EXTENSION *
	
	chmod 400 $NAME.1$EXTENSION
	mv $NAME.1$EXTENSION $DEST/
	cd ..
}

# check arguments
if [ "${#*}" -ne 3 ]; then
	print_help
	exit 1
fi

SRC=$1
DEST=$2
NAME=$3

if [ ! -e "$TMP" ]; then
	mkdir $TMP
fi
	
chmod 700 $TMP

archive
rotate
package

rm -rf $TMP


exit 0
