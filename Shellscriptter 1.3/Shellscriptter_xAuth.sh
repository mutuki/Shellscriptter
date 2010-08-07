#!/bin/bash

# xAuth bash Core version 1.0, optimaze for twitter.com version.
# Script written by Hiroshi Ogawa
# See more information http://www.kuropug.com/Shellscriptter/
# Last modify 17th February 2010

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

## GET Access token part ##
# Application KEY and SECRET
# If you want to use it for your Application, You should be chage below values.
CKEY="TyE3ffHPCOfnZgIKRb93A"
CSECRET="Dv63v7NXWCTiQMtxSAcW58mlpGpNCRXHuTFqukxlw&"
UNAME=$1
UPASS=$2

# Display key parameters (Debug mode) 
if [ ${debug:-off} = "on" ]; then
echo "Below, your key parameters."
echo "Customer Key : $CKEY"
echo "Customer Secret : $CSECRET"
echo "Your user name : $UNAME"
echo "Your password : $UPASS"
fi

# UNIXTIME-STAMP and NONCE Generator
TIMESTAMP=`date +%s`
NONCEDATA=`jot -r 1 10000000000 99999999999`

# Request parameter
REQUESTPAR="oauth_consumer_key=$CKEY&oauth_nonce=$NONCEDATA&oauth_signature_method=HMAC-SHA1&oauth_timestamp=$TIMESTAMP&oauth_version=1.0&x_auth_mode=client_auth&x_auth_password=$UPASS&x_auth_username=$UNAME"

# Display accsess parameters (Debug mode) 
if [ ${debug:-off} = "on" ]; then
echo "Access parameters are"
echo $REQUESTPAR
fi

# Oauth Signature, HMAC-SHA1 with Customer SECRET
ENCREQUESTPAR=`echo -n $REQUESTPAR | sed 's/=/%3D/g' | sed 's/&/%26/g'`
QUERYDATA="GET&https%3A%2F%2Fapi.twitter.com%2Foauth%2Faccess_token&$ENCREQUESTPAR"
HASHDATA=`echo -n "$QUERYDATA" | openssl sha1 -hmac "$CSECRET" -binary | openssl base64 | sed 's/\//%2F/g' | sed 's/=/%3D/g' | sed 's/+/%2B/g'`

# Display hashed signature (Debug mode) 
if [ ${debug:-off} = "on" ]; then
echo "Hashed signature is"
echo $HASHDATA
fi

# Display HTTP GET Query (Debug mode) 
if [ ${debug:-off} = "on" ]; then
echo "HTTP GET process start, strings are below. "
echo "https://api.twitter.com/oauth/access_token?$REQUESTPAR&oauth_signature=$HASHDATA"
fi
 
ACCESSTOKEN=`curl --url "https://api.twitter.com/oauth/access_token?$REQUESTPAR&oauth_signature=$HASHDATA"`

AKEY=`echo -n $ACCESSTOKEN | tr '&' '\n' | sed -e '2,5D' | sed 's/oauth_token=//g'`
ASECRET=`echo -n $ACCESSTOKEN | tr '&' '\n' | sed -e '1D' | sed -e '2,4D' | sed 's/oauth_token_secret=//g'`

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