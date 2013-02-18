#!/bin/bash

CONFFILE=`dirname $0`/.Shellscriptter.conf
source "$CONFFILE"

while getopts drtx: sw
	do
        case $sw in
        "d" )
                debug="on"
                ;;
        "r" )
                ruby="on"
                ;;
		"t" )
				timeline="on"
				;;
		"x" )
                useProxy="true"
                Proxyurl="$OPTARG"
                ;;
        *)
                ;;
        esac
done

if [ ${debug:-off} = "on" ]; then
	 echo $'\n'"========================= KEY INFORMATION ============================="
	 echo "Cons Token:	$CKEY"
	 echo "Cons Secret:	$CSECRET"
	 echo "Access Token:	$AKEY"
	 echo "Access Secret:	$ASECRET"
	 echo "======================================================================="$'\n'
fi

## Shellscriptter Core part ##
# UNIXTIME-STAMP and NONCE Generator
TIMESTAMP=`date +%s`
NONCEDATA=`uuidgen | tr -d "-" | tr "[A-Z]" "[a-z]"`


REQUESTPAR="oauth_consumer_key=$CKEY&oauth_nonce=$NONCEDATA&oauth_signature_method=HMAC-SHA1&oauth_timestamp=$TIMESTAMP&oauth_token=$AKEY&oauth_version=1.0"
ENCREQUESTPAR=`echo -n $REQUESTPAR | sed 's/%/%25/g' |sed 's/=/%3D/g' | sed 's/&/%26/g'`
QUERYDATA="GET&https%3A%2F%2Fapi.twitter.com%2F1.1%2Fstatuses%2Fhome_timeline.json&$ENCREQUESTPAR"
HASHDATA=`echo -n "$QUERYDATA" | openssl sha1 -hmac "$CSECRET$ASECRET" -binary | openssl base64 | sed 's/\//%2F/g' | sed 's/=/%3D/g' | sed 's/+/%2B/g'`
HEADERDATA="Authorization: OAuth oauth_consumer_key=$CKEY, oauth_nonce=$NONCEDATA, oauth_signature=$HASHDATA, oauth_signature_method=HMAC-SHA1, oauth_timestamp=$TIMESTAMP, oauth_token=$AKEY, oauth_version=1.0"
	
POSTEDDATA=`curl --get 'https://api.twitter.com/1.1/statuses/home_timeline.json' --header "$HEADERDATA" --silent`

if [ ${debug:-off} = "on" ]; then
	echo $POSTEDDATA | perl -pe 's/,{\"created_at/\n{\"created_at/g' > debugSource.json	
fi

TIMELINE=`echo $POSTEDDATA | perl -pe 's/,{\"created_at/\n{\"created_at/g' | awk 'BEGIN {FS=","} {print $15,$4}' | sed 's/\"screen_name\":\"//g' | sed 's/\" \"text\":\"/ : /g' | sed 's/\"\$//g'`

if [ ${debug:-off} = "on" ]; then
	echo "$TIMELINE" >timeline.txt
fi

echo "$TIMELINE" | perl -pe 's/\\\//\//g' > home.txt

./decode.py