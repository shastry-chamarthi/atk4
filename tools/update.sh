#!/bin/bash

set -e	 # exit if anything fails

config='../config.php';
[ -f $config ] || config='../../config.php';
[ -f $config ] || config='../../../config.php';

dsn=`cat $config | grep "config\['dsn'\]" | grep -vP '^\s*(//|#)' | cut -d= -f2 | sed "s/'/\"/g" | cut -d\" -f2 | sed 's|mysql://||'`
u=`echo $dsn | cut -d: -f1`
p=`echo $dsn | cut -d: -f2 | cut -d@ -f1`
db=`echo $dsn | cut -d/ -f2`

[ "$db" ] || { echo "Error: Can't read config file"; exit; }

if [ -f ~/.my.cnf ]; then
	mysql="mysql $db"
else
	mysql="mysql -u$u -p$p $db"
fi

echo "* Applying updates on database '$db'"

cd dbupdates
for x in *.sql; do 
	[ -f $x.ok ] && continue
	echo -n " $x... "
	
	# user and password must be in ~/.my.cnf
	if $mysql -B < $x 2> $x.fail; then
		mv $x.fail $x.ok
		echo 'ok'
	else
		echo 'fail'
		cat $x.fail
		echo
	fi
done
cd ..

if [ -d 'storedfx' ]; then
	echo "* Re-Importing stored procedures"
	
	cnt=0
	for x in storedfx/*manual ; do 
		if $mysql -B < $x 2> $x.fail ; then
			rm $x.fail
			cnt=$(( $cnt + 1 ))
		else
			echo -n " $x... "
			echo 'fail'
			cat $x.fail
			echo
		fi
	done
	echo " $cnt procedures imported"
fi

echo "* Done"
