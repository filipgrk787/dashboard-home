#!/bin/bash

DB="/home/filipgrk/ping_data.db"
TARGET="www.google.com"

while true; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    ping_result=$(ping -c 1 -W 2 $TARGET)

    if echo "$ping_result" | grep -q "time="; then
        latency=$(echo "$ping_result" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')
        sqlite3 "$DB" "INSERT INTO pings (timestamp, success, latency) VALUES ('$timestamp', 1, $latency);"
    else
        sqlite3 "$DB" "INSERT INTO pings (timestamp, success, latency) VALUES ('$timestamp', 0, NULL);"
    fi

    # Sleep for 30 seconds before next ping
    sleep 10
done