#!/bin/bash

# Get OPTIONS
# -d is debug mode. When you set -d, It will be shown posting paramaters.
while getopts drtx: sw
	do
        case $sw in
        "d" )
                debug="on"
                ;;
        *)
                ;;
        esac
done				

# Set target location
# Refer http://bulk.openweathermap.org/sample/city.list.json.gz
LOCATION=1850147

# Get Weather paramters
RAWDATA=`curl "https://api.openweathermap.org/data/2.5/weather?id=$LOCATION&appid=73894253bc1837e30cdde1bc6549a864&lang=ja&units=Metric" --silent`

# Separate 
MASTERDATA=`echo $RAWDATA | sed -e 's/\"weather/\'$'\n\"weather/' -e 's/\"base/\'$'\n\"base/' -e 's/\"visibility/\'$'\n\"visibility/' -e 's/\"clouds/\'$'\n\"clouds/' -e 's/\"visibility/\'$'\n\"visibility/' -e 's/\"dt/\'$'\n\"dt/' -e 's/\"sys/\'$'\n\"sys/'`

if [ ${debug:-off} = "on" ]; then
echo -e "MASTERDATA are below :\n$MASTERDATA\n"
fi

# get weather 
WEATHER=`echo "$MASTERDATA" | grep -e weather | tr ',' '\n' | grep -e id | sed -e 's/{\"id\"://g' -e 's/\"weather\":\[//' `

if [ ${debug:-off} = "on" ]; then
echo -e "WEATHER are below :\n$WEATHER\n"
fi

SUNRISE=`echo "$MASTERDATA" | grep -e sys | tr ',' '\n' | tr -d '"' | tr -d '}' | grep -e sunrise | tr -d 'sunrise:'`
SUNSET=`echo "$MASTERDATA" | grep -e sys | tr ',' '\n' | tr -d '"' | tr -d '}' | grep -e sunset | tr -d 'sunset:'`
CURRENTSKY=`date +%s`

if [ ${debug:-off} = "on" ]; then
echo -e "DAYLIGHT time information :\n$SUNRISE to $SUNSET and current time is $CURRENTSKY"
	
	if [ $SUNRISE -lt $CURRENTSKY ] && [ $CURRENTSKY -lt $SUNSET ]; then
		echo "will sunrise."
	else
		echo "will sunset."	
	fi	

fi

if [ $SUNRISE -lt `date +%s` ] && [ `date +%s` -lt $SUNSET ]; then
	WEATHER=`echo "$WEATHER" | sed -e 's/2[0-9][0-9]/⛈/g' -e 's/3[0-9][0-9]/☂️/g' -e 's/5[0-9][0-9]/☔️/g' -e 's/6[0-9[0-9]*/❄️/g' -e 's/7[0-9][0-9]/🌫/g' -e 's/800/☀️/g' -e 's/801/🌤/g' -e 's/802/⛅️/g' -e 's/803/🌥/g' -e 's/804/☁️/g'| head -n 1`
else
	WEATHER=`echo "$WEATHER"	| sed -e 's/2[0-9][0-9]/⛈/g' -e 's/3[0-9][0-9]/☂️/g' -e 's/5[0-9][0-9]/☔️/g' -e 's/6[0-9[0-9]*/❄️/g' -e 's/7[0-9][0-9]/🌫/g' -e 's/8[0-9]*/🌕/g' | head -n 1`
fi

TEMPERATURE=`echo "$MASTERDATA" | grep -e base | tr ',' '\n' | tr -d '"' | tr -d '}' | grep -e main | sed -e 's/main:{temp://'`
HUMIDITY=`echo "$MASTERDATA" | grep -e base | tr ',' '\n' | tr -d '"' | tr -d '}' | grep -e humidity | sed -e 's/humidity://'`


echo "現在の天気は$WEATHER""、気温は$TEMPERATURE""°、湿度は$HUMIDITY%。Powered by #OpenWeatherMap"