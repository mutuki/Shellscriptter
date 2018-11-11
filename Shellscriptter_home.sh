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
	
RAWDATA=`curl --get 'https://api.twitter.com/1.1/statuses/home_timeline.json' --header "$HEADERDATA" --silent`

if [ ${debug:-off} = "on" ]; then
	echo $RAWDATA > rawdata.json
fi

TWEETDATA=`echo "$RAWDATA" | sed -e 's/\[//' -e 's/\]$//' -e 's/\"retweeted_status/\'$'\n\"retweeted_status/g' -e 's/,{\"created_at/\'$'\n{"created_at/g' | grep -v \"retweeted_status | sed -e 's/\"user\":{/\'$'\n\"user\":{/g' -e 's/\"entities\":{/\'$'\n\"entities\":{/g' | grep -v \"entities | sed -e 's/{/{\'$'\n/g' -e 's/}/\'$'\n}/g' -e 's/\",/\"\'$'\n/g' | grep -e ^\"created_at -e ^\"text -e ^\"name | tr -d '"'`

if [ ${debug:-off} = "on" ]; then
	echo $TWEETDATA
fi

echo "$TWEETDATA" > home.txt 
./decode.py | grep '.' | tr -d '\n' | sed -e 's/created_at://' -e 's/text:/ :/g' -e 's/name:/ - tweet by /g' -e 's/created_at:/\'$'\n/g'