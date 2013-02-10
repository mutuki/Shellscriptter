#!/bin/bash

# OAuth bash Core version 1.1, optimaze for twitter.com version.
# Script written by Hiroshi Ogawa
# See more information http://www.kuropug.com/Shellscriptter/
# Last modify 11th February 2013

## Initialize part ##
# inclued Authentication Parameters
CONFFILE=`dirname $0`/.Shellscriptter.conf
if [ -f "$CONFFILE" ]; then
	source "$CONFFILE"
else
	echo "Do Shellscriptter_OAuth.sh first"
	exit 0
fi

# Get OPTIONS method written by t.taniguti
# -d is debug mode. When you set -d, It will be shown posting paramaters.
# -x is using proxy.
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
	echo $'\n'"Enable DEBUG mode..."$'\n'
	echo "Num of parm is $#"
	echo "useproxy(-x)  is ${useProxy:-false}"
	echo "Proxyurl is ${Proxyurl:-NONE}"
	echo "debug(-d) is ${debug:-off}"
	echo "OPTIND is $OPTIND"
fi

shift `expr $OPTIND - 1`

if [ ${debug:-off} = "on" ]; then
	echo "Num of parm is $#"
	echo "Proxyurl is ${Proxyurl:-NONE}"
fi

if [ ${Proxyurl:-NONE} != NONE ]; then
	curlproxyurl="-x $Proxyurl"
fi

if [ ${debug:-off} = "on" ]; then       
	echo "curlproxyurl is ${curlproxyurl:-NONE}"
fi

# Diplay inclued data (Debug mode)
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

# URLEncodey Library $1 is text value (came from Shellscriptter.sh "option")
# Blank=%20, !=%21, #=%23, $=%24, %=%25, &=%26,'=%27, (=%28, )=%29, /=%2F, :=%3A, ?=%3F
# First It must be replace %=%25
# When you set debug on (given -d), It will be bale to multibyte charactors tweet. However it works reqired Ruby 1.8.
if [ ${ruby-off} = "on" ];then
	RESULT=`ruby -e "require 'uri' ; puts URI.encode('$1', Regexp.new('[^-_.0-9a-zA-Z]') )" `
else
	RESULT=`echo -n $1 | sed 's/%/%25/g' | sed 's/ /%20/g' | sed 's/!/%21/g' | sed 's/#/%23/g' | sed "s/&/%26/g" | sed "s/'/%27/g" | sed 's/(/%28/g' | sed 's/)/%29/g' | sed 's/\//%2F/g' | sed 's/:/%3A/g' | sed 's/?/%3F/g'`
fi

# Display URLEncode status data (Debug mode)
if [ ${debug:-off} = "on" ]; then
	echo "status is : $RESULT"
fi

# OAuth signature generator
REQUESTPAR="oauth_consumer_key=$CKEY&oauth_nonce=$NONCEDATA&oauth_signature_method=HMAC-SHA1&oauth_timestamp=$TIMESTAMP&oauth_token=$AKEY&oauth_version=1.0&status=$RESULT"
ENCREQUESTPAR=`echo -n $REQUESTPAR | sed 's/%/%25/g' |sed 's/=/%3D/g' | sed 's/&/%26/g'`
QUERYDATA="POST&https%3A%2F%2Fapi.twitter.com%2F1.1%2Fstatuses%2Fupdate.json&$ENCREQUESTPAR"
HASHDATA=`echo -n "$QUERYDATA" | openssl sha1 -hmac "$CSECRET$ASECRET" -binary | openssl base64 | sed 's/\//%2F/g' | sed 's/=/%3D/g' | sed 's/+/%2B/g'`

# Display Signature base string (Debug mode)
if [ ${debug:-off} = "on" ]; then
	echo "Signature base string : $QUERYDATA"
fi

HEADERDATA="Authorization: OAuth oauth_consumer_key=$CKEY, oauth_nonce=$NONCEDATA, oauth_signature=$HASHDATA, oauth_signature_method=HMAC-SHA1, oauth_timestamp=$TIMESTAMP, oauth_token=$AKEY, oauth_version=1.0"

# Display Authorization header (Debug mode)
if [ ${debug:-off} = "on" ]; then
	echo "Authorization header : $HEADERDATA"
fi

# Post https://api.twitter.com/1.1/statuses/update.json
if [ ${debug:-off} = "on" ]; then
	echo "Try to tweet."
	POSTEDDATA=`curl --request 'POST' 'https://api.twitter.com/1.1/statuses/update.json' --data "status=$RESULT" --header "$HEADERDATA" --verbose`
	echo $POSTEDDATA
else 
	POSTEDDATA=`curl --request 'POST' 'https://api.twitter.com/1.1/statuses/update.json' --data "status=$RESULT" --header "$HEADERDATA" --silent`
	echo $POSTEDDATA>/tmp/Shellscriptter_tweet_update.json
fi
 
# if [ ${timeline:-off} = "on" ]; then
# HOMETIMESTAMP=`date +%s`
# HOMENONCEDATA=`jot -r 1 10000000000 99999999999`
# 
# HOMEREQUESTPAR="oauth_consumer_key=$CKEY&oauth_nonce=$HOMENONCEDATA&oauth_signature_method=HMAC-SHA1&oauth_timestamp=$HOMETIMESTAMP&oauth_token=$AKEY&oauth_version=1.0"
# HOMEENCREQUESTPAR=`echo -n $HOMEREQUESTPAR | sed 's/%/%25/g' |sed 's/=/%3D/g' | sed 's/&/%26/g'`
# HOMEQUERYDATA="GET&http%3A%2F%2Fapi.twitter.com%2F1%2Fstatuses%2Fhome_timeline.xml&$HOMEENCREQUESTPAR"
# HOMEHASHDATA=`echo -n "$HOMEQUERYDATA" | openssl sha1 -hmac "$CSECRET$ASECRET" -binary | openssl base64 | sed 's/\//%2F/g' | sed 's/=/%3D/g' | sed 's/+/%2B/g'`
# 
# curl -s --url "http://api.twitter.com/1/statuses/home_timeline.xml?$HOMEREQUESTPAR&oauth_signature=$HOMEHASHDATA" > /tmp/home_timeline.xml
# xsltproc `dirname $0`/homeTimeline.xsl /tmp/home_timeline.xml
# fi