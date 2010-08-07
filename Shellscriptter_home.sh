#!/bin/bash

CONFFILE=`dirname $0`/.Shellscriptter.conf
source "$CONFFILE"

echo $CKEY
echo $CSECRET
echo $AKEY
echo $ASECRET

TIMESTAMP=`date +%s`
NONCEDATA=`jot -r 1 10000000000 99999999999`

REQUESTPAR="oauth_consumer_key=$CKEY&oauth_nonce=$NONCEDATA&oauth_signature_method=HMAC-SHA1&oauth_timestamp=$TIMESTAMP&oauth_token=$AKEY&oauth_version=1.0&status=$RESULT"
ENCREQUESTPAR=`echo -n $REQUESTPAR | sed 's/%/%25/g' |sed 's/=/%3D/g' | sed 's/&/%26/g'`
QUERYDATA="GET&http%3A%2F%2Fapi.twitter.com%2F1%2Fstatuses%2Fhome_timeline.xml&$ENCREQUESTPAR"
HASHDATA=`echo -n "$QUERYDATA" | openssl sha1 -hmac "$CSECRET$ASECRET" -binary | openssl base64 | sed 's/\//%2F/g' | sed 's/=/%3D/g' | sed 's/+/%2B/g'`

curl -s --url "http://api.twitter.com/1/statuses/home_timeline.xml?$REQUESTPAR&oauth_signature=$HASHDATA" > /tmp/home_timeline.xml
xsltproc `dirname $0`/homeTimeline.xsl /tmp/home_timeline.xml