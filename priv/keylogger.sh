#!/bin/bash

while :; do
    read -n 1 keypress
    if [ "$keypress" == "1" ]; then
        echo "Foot switch is pressed"
        redis-cli publish photobooth.event countdown
    else
        echo "Unknown key: $keypress"
    fi
done
