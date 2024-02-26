#!/bin/bash

echo -n "Enter Jamf Server URL [https://your.jamf.server]: "
read url
echo -n "Enter Jamf Server username: "
read jssuser
echo -n "Enter the password for ${jssuser}: "
stty -echo
read jsspass
stty echo
echo ""


if [ -e /tmp/jcdsfiles ];then
	rm /tmp/jcdsfiles
fi

function epoch() {
	now=$(date "+%Y-%m-%d %T")
	echo $(date -j -f "%Y-%m-%d %T" "$now" +%s)
}

function getToken() {
	authToken=$(curl -sk \
-u ${jssuser}:${jsspass} \
--request POST \
--url ${url}/api/v1/auth/token \
--header "Accept: application/json"
)
	#	echo "URL: ${url}/api/v1/auth/token"
	echo "authToken: $authToken" >$(tty)
	local theToken=$(/usr/bin/plutil -extract token raw -o - - <<< "$authToken")
	echo $theToken
}

function getList() {
	# list all the packages
	echo "Getting a list of packages from JCDS"
	echo """query: 
curl --request GET 
	--silent 
	--header "authorization: Bearer $token" 
	--header 'Accept: application/json' 
	"$url/api/v1/jcds/files" 
	--write-out "%{http_code}" 
"""
	start=$(date "+%Y-%m-%d %T")
	startEpoch=$(date -j -f "%Y-%m-%d %T" "$start" +%s)
	http_response=$(
		curl --request GET \
			--silent \
			--header "authorization: Bearer $token" \
			--header 'Accept: application/json' \
			"$url/api/v1/jcds/files" \
			--write-out "%{http_code}" \
			--location \
			--output "/tmp/jcdsfiles"
	)
	end=$(date "+%Y-%m-%d %T")
	endEpoch=$(date -j -f "%Y-%m-%d %T" "$end" +%s)
	diff=$(( $endEpoch-$startEpoch ))
	echo "HTTP response: $http_response"
	echo "response time: $diff seconds"
	echo ""
	
	#	if [[ $http_response -eq 200 ]]; then
	echo $(date)
	echo "package plist"		
	cat "/tmp/jcdsfiles"
	echo ""
	fileCount=$(cat "/tmp/jcdsfiles" | grep \"fileName\" -c)
	echo "found $fileCount packages"
	echo ""
	#	fi
}

startEpoch=$(epoch)
echo "startEpoch: $startEpoch"
echo $(date)
token=$(getToken) 
echo "token: $token"
endEpoch=$(epoch)
echo "endEpoch: $endEpoch"
diff=$(( $endEpoch-$startEpoch ))
echo "response time: $diff seconds"

getList
