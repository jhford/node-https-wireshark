#!/bin/bash 

## To use this, put this script next to your package.json file and run `sudo ./yarnshark.js`
## then you should have two files, yarn.pcap and SSLKEYLOG
## Use those files to follow instructions here:  https://jimshaver.net/2015/02/11/decrypting-tls-browser-traffic-with-wireshark-the-easy-way/

YARN_RUNTIME_LOCATION="$(dirname "$(readlink -f "$(which yarn)")")"

if [ ! -f "$YARN_RUNTIME_LOCATION/sslkeylogger.js" ]; then
  curl -s "https://raw.githubusercontent.com/forestjohnsonpeoplenet/node-https-wireshark/master/index.js" > "$YARN_RUNTIME_LOCATION/sslkeylogger.js"
fi
cp "$YARN_RUNTIME_LOCATION/yarn.js" "$YARN_RUNTIME_LOCATION/yarn.js.bak"

YARN_CLI_LINE_NUMBER="$(cat "$YARN_RUNTIME_LOCATION/yarn.js" | grep -n -e "^ *var cli = require" | sed "s/\\([0-9][0-9]*\\):.*/\\1/")"
YARN_CLI_LINE_NUMBER=$(($YARN_CLI_LINE_NUMBER - 1))

FIRST_HALF=$(cat "$YARN_RUNTIME_LOCATION/yarn.js" | head -n $YARN_CLI_LINE_NUMBER)
LAST_HALF=$(cat "$YARN_RUNTIME_LOCATION/yarn.js" | tail -n +$(($YARN_CLI_LINE_NUMBER + 1)) ) 

echo "$FIRST_HALF" > "$YARN_RUNTIME_LOCATION/yarn.js"
echo "require(\"./sslkeylogger\")" >> "$YARN_RUNTIME_LOCATION/yarn.js"
echo "console.log(\"This yarn is logging HTTPS session keys using https://github.com/forestjohnsonpeoplenet/node-https-wireshark\")" >> "$YARN_RUNTIME_LOCATION/yarn.js"
echo "$LAST_HALF" >> "$YARN_RUNTIME_LOCATION/yarn.js"

#echo "$YARN_RUNTIME_LOCATION/yarn.js"
#cat "$YARN_RUNTIME_LOCATION/yarn.js"

tcpdump -i any -s 65535 -w yarn.pcap &

TCPDUMP_PID=$!

SSLKEYLOGFILE="$(pwd)/SSLKEYLOG" yarn $@

kill $TCPDUMP_PID

rm "$YARN_RUNTIME_LOCATION/sslkeylogger.js"
rm "$YARN_RUNTIME_LOCATION/yarn.js"
mv "$YARN_RUNTIME_LOCATION/yarn.js.bak" "$YARN_RUNTIME_LOCATION/yarn.js"

