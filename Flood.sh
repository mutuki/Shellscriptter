#!/bin/bash

# Get OPTIONS
# -d is debug mode. When you set -d, It will be shown posting paramaters.
while getopts ad: sw
	do
        case $sw in
		"a" )
				all="on"
				;;
        "d" )
                debug="on"
                ;;
        *)
                ;;
        esac
done				

# Get flood information
RAWDATA=`curl http://www.jma.go.jp/jp/flood/103.html | grep "tablelist"` 

if [ ${debug:-off} = "on" ]; then
	echo -e "RAWDATA are below :\n$RAWDATA\n"
fi

# Saparate
MASTERDATA=`echo -e "$RAWDATA" | sed -e 's/\/tr>/\/tr>\'$'\n/g' -e 's/<[^>]*>/ /g' -e 's/([^)]*)/ /g' -e 's/令和元/2019/g' -e '/^$/d' | grep -v nbsp | sed -e '$d' -e '1d'`

# Show All Data
ALLDATA=`echo -e "$MASTERDATA" | awk '{print $3,$1,$2}' | awk '!a[$2]++' | sort -r | awk '{print $3, ":", $2 "（" $1 "）"}'`

if [ ${all:-off} = "on" ]; then
	echo -e "$ALLDATA"
fi

# Tweet Data
if [ ${all:-off} = "off" ]; then
	echo -e "関東甲信の河川洪水予報（最新3件）"
	echo -e "$ALLDATA" | head -n 3
	echo -e "Powered by #気象庁"
fi