#!/bin/bash

ENABLE="$1"

REBOOT_DELAY_TIME="$2"

OPENSSL_CNF_DEFAULT="/etc/default/openssl.cnf"
OPENSSL_CNF="/etc/ssl/openssl.cnf"
OPENSSL_CNF_TMP="/etc/ssl/openssl.cnf.tmp"
FIPS_CNF="/etc/ssl/fipsmodule.cnf"

FIPS_SO="/usr/lib/ossl-modules/fips.so"

reboot_after_change () {
        sleep $REBOOT_DELAY_TIME
        reboot
} 

fips_on () {
	openssl fipsinstall -module "$FIPS_SO" -out "$FIPS_CNF" -provider_name fips > /dev/null 2>&1
	cp -f $OPENSSL_CNF_DEFAULT $OPENSSL_CNF_TMP
	sed -i "s/^# fips = fips_sect/fips = fips_sect\nbase = base_sect\n\n\[base_sect\]\nactivate = 1\n\n.include \/etc\/ssl\/fipsmodule.cnf/g" $OPENSSL_CNF_TMP
	sed -i 's/^default = default_sect/# default = default_sect/g' $OPENSSL_CNF_TMP
	mv $OPENSSL_CNF_TMP $OPENSSL_CNF
}

fips_off () {
	cp -f $OPENSSL_CNF $OPENSSL_CNF_TMP
	sed -i 's/^fips = fips_sect/# fips = fips_sect/g' $OPENSSL_CNF_TMP
	sed -i '/base = base_sect/,+1d' $OPENSSL_CNF_TMP
	sed -i '/\[base_sect\]/,+2d' $OPENSSL_CNF_TMP
	sed -i '/.include \/etc\/ssl\/fipsmodule.cnf/d' $OPENSSL_CNF_TMP
	sed -i 's/^# default = default_sect/default = default_sect/g' $OPENSSL_CNF_TMP
	mv $OPENSSL_CNF_TMP $OPENSSL_CNF
	rm -f $FIPS_CNF > /dev/null 2>&1
}

case $ENABLE in
	"init_on" )
		fips_on
		;;
	"on" )
		fips_on
		reboot_after_change &
		;;
	"off" )
		fips_off
		reboot_after_change &
		;;
	*)
		echo "Usage: $0 on/off"
		;;
esac