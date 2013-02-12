#!/bin/bash

# OAuth bash Core version 2.0, optimaze for twitter API version 1.1.
# Script written by Hiroshi Ogawa
# See more information https://github.com/mutuki/Shellscriptter/wiki
# Last modify 13th February 2013

## Initialize part ##
# When you get a OAuth Access token, It will be make a configuration file below.
CONFFILE=`dirname $0`/.Shellscriptter.conf

# Get OPTIONS method written by t.taniguti
# -d is debug mode. When you set -d, It will be shown posting paramaters.
# -f is force mode. It works force authentication mode (remove and recreate Access KEY and SECRET)
# -x is using proxy.
while getopts dfx: sw
do
        case $sw in
        "d" )
                debug="on"
                ;;
        "f" )
                doForce="true"
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
        echo "Num of parm is $#"
        echo "useproxy(-x)  is ${useProxy:-false}"
        echo "Proxyurl is ${Proxyurl:-NONE}"
        echo "doForce(-f)  is ${doForce:-false}"
        echo "debug(-d)  is ${debug:-off}"
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

# Check if CONFFILE was make already, It will be check "force" option.
if [ ${doForce:-false} = "true" ]; then
	rm -f -v "$CONFFILE"
fi
if [ -f "$CONFFILE" ]; then
	echo "You have done authentication." 
	echo "Enjoy Shellscriptter.sh!" 
	exit 0
fi 

## GET Request token part ##
# These are "Consumer KEY" and "Consumer SECRET"
# If you want to use it for your Application, You should be chage below values.
CKEY="TyE3ffHPCOfnZgIKRb93A"
CSECRET="Dv63v7NXWCTiQMtxSAcW58mlpGpNCRXHuTFqukxlw&"

# UNIXTIME-STAMP and NONCE Generator
TIMESTAMP=`date +%s`
NONCEDATA=`uuidgen | tr -d "-" | tr "[A-Z]" "[a-z]"`

# Request parameter
REQUESTPAR="oauth_consumer_key=$CKEY&oauth_nonce=$NONCEDATA&oauth_signature_method=HMAC-SHA1&oauth_timestamp=$TIMESTAMP&oauth_version=1.0"

# Oauth Signature, HMAC-SHA1 with Customer SECRET
ENCREQUESTPAR=`echo -n $REQUESTPAR | sed 's/=/%3D/g' | sed 's/&/%26/g'`
QUERYDATA="GET&https%3A%2F%2Fapi.twitter.com%2Foauth%2Frequest_token&$ENCREQUESTPAR"
HASHDATA=`echo -n "$QUERYDATA" | openssl sha1 -hmac "$CSECRET" -binary | openssl base64 | sed 's/\//%2F/g' | sed 's/=/%3D/g' | sed 's/+/%2B/g'`

# Display HTTP GET Query (Debug mode) 
if [ ${debug:-off} = "on" ]; then
 echo "https://api.twitter.com/oauth/request_token?$REQUESTPAR&oauth_signature=$HASHDATA"
fi

# Post http://twitter.com/oauth/request_token
REQUESTTOKEN=`curl --url "https://api.twitter.com/oauth/request_token?$REQUESTPAR&oauth_signature=$HASHDATA"`

# Generate Request KEY and SECRET
RKEY=`echo -n $REQUESTTOKEN | tr '&' '\n' | sed -e '2,3D' | sed 's/oauth_token=//g'`
RSECRET=`echo -n $REQUESTTOKEN | tr '&' '\n' | sed -e '1D' | sed -e '2D' | sed 's/oauth_token_secret=//g'`

# Display Reuquest attributes (Debug mode)
if [ ${debug:-off} = "on" ]; then
 echo $REQUESTTOKEN
 echo $RKEY
 echo $RSECRET
fi

## User Authentication part ##
# Open Authentication Page
# If your platform is without OS X, enable blow echo command, disable "open" command and joint secondary line.
# echo "Open your browser with URL"$'\n' 
open https://api.twitter.com/oauth/authorize?oauth_token=$RKEY 

# Ask PIN Number
echo "it will be open http://api.twitter.com/oauth/authorize Get and Input PIN Number"
read PINNUMBER

## GET Access token part ##
# UNIXTIME-STAMP and NONCE Generator2 (agin)
TIMESTAMP2=`date +%s`
NONCEDATA2=`uuidgen | tr -d "-" | tr "[A-Z]" "[a-z]"`

# Request parameter
REQUESTPAR2="oauth_consumer_key=$CKEY&oauth_nonce=$NONCEDATA2&oauth_signature_method=HMAC-SHA1&oauth_timestamp=$TIMESTAMP2&oauth_token=$RKEY&oauth_verifier=$PINNUMBER&oauth_version=1.0"

# Oauth Signature, HMAC-SHA1 with Customer SECRET and Request SECRET
ENCREQUESTPAR2=`echo -n $REQUESTPAR2 | sed 's/=/%3D/g' | sed 's/&/%26/g'`
QUERYDATA2="GET&https%3A%2F%2Fapi.twitter.com%2Foauth%2Faccess_token&$ENCREQUESTPAR2"
HASHDATA2=`echo -n "$QUERYDATA2" | openssl sha1 -hmac "$CSECRET$RSECRET" -binary | openssl base64 | sed 's/\//%2F/g' | sed 's/=/%3D/g' | sed 's/+/%2B/g'`

# Display HTTP GET Query (Debug mode) 
if [ ${debug:-off} = "on" ]; then
 echo "https://api.twitter.com/oauth/access_token?$REQUESTPAR2&oauth_signature=$HASHDATA2"
fi

# Post http://twitter.com/oauth/access_token
ACCESSTOKEN=`curl --url "https://api.twitter.com/oauth/access_token?$REQUESTPAR2&oauth_signature=$HASHDATA2"`

# Generate Access KEY and SECRET
AKEY=`echo -n $ACCESSTOKEN | tr '&' '\n' | sed -e '2,4D' | sed 's/oauth_token=//g'`
ASECRET=`echo -n $ACCESSTOKEN | tr '&' '\n' | sed -e '1D' | sed -e '2,3D' | sed 's/oauth_token_secret=//g'`

# Display Access attributes (Debug mode)
if [ ${debug:-off} = "on" ]; then
 echo $ACCESSTOKEN
 echo $AKEY
 echo $ASECRET
fi

# OAuth prossess success notification and save paramaters.
echo "RESULT Exporting..."
echo "#!/bin/bash"$'\n'"CKEY='$CKEY'"$'\n'"CSECRET='$CSECRET'"$'\n'"AKEY='$AKEY'"$'\n'"ASECRET='$ASECRET'" > "$CONFFILE"
chmod 600 "$CONFFILE"
echo "Your OAuth porcesses are success!"
