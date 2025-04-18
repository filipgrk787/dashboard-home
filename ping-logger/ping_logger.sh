#!/bin/bash

# === Config ===
TARGET="www.google.com"
EMAIL_TO="filipgrk@gmail.com"

LOG_FILE="$HOME/ping_loss.log"
SUMMARY_FILE="$HOME/ping_summary.log"

declare -a response_times

# === Counters ===
total_pings=0
failed_pings=0
successful_pings=0
total_response_time=0
start_time=$(date +%s)
last_email_sent=$start_time

CSV_LOG="$HOME/ping_data.csv"

# Write CSV header once if file doesn't exist
if [ ! -f "$CSV_LOG" ]; then
    echo "timestamp,success,latency_ms" > "$CSV_LOG"
fi

# === Functions ===

timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if echo "$output" | grep -q "time="; then
    	echo "$timestamp,1,$ms" >> "$CSV_LOG"
    else
    	echo "$timestamp,0," >> "$CSV_LOG"
    fi

calculate_median() {
    sorted=($(printf "%s\n" "${response_times[@]}" | sort -n))
    count=${#sorted[@]}
    
    if (( count == 0 )); then
        echo "0"
    elif (( count % 2 == 1 )); then
        echo "${sorted[$((count/2))]}"
    else
        mid1=${sorted[$((count/2 - 1))]}
        mid2=${sorted[$((count/2))]}
        echo $(awk "BEGIN { printf \"%.2f\", ($mid1 + $mid2) / 2 }")
    fi
}

write_summary() {
    current_time=$(date)
    elapsed=$(( $(date +%s) - start_time ))
    loss_percentage=$(awk "BEGIN { printf \"%.2f\", ($failed_pings/$total_pings)*100 }")

    if [ $successful_pings -gt 0 ]; then
        avg_response=$(awk "BEGIN { printf \"%.2f\", $total_response_time / $successful_pings }")
    else
        avg_response="N/A"
    fi

    {
        echo "Ping Summary Report for $TARGET"
        echo "Timestamp: $current_time"
        echo "Total pings: $total_pings"
        echo "Successful pings: $successful_pings"
        echo "Failed pings: $failed_pings"
        echo "Packet loss: $loss_percentage%"
        echo "Average response time: ${avg_response} ms"
        echo "Elapsed time: $elapsed seconds"
        echo "------------------------------------------"
    } | tee -a "$SUMMARY_FILE"
}

send_email_summary() {
    SUBJECT="Ping Summary for $TARGET"
    mail -s "$SUBJECT" "$EMAIL_TO" < "$SUMMARY_FILE"
    echo "[$(date)] Email summary sent to $EMAIL_TO" >> "$LOG_FILE"
    > "$SUMMARY_FILE"
}

send_urgent_email() {
    SUBJECT="URGENT: High Latency Alert to $TARGET"
    {
        echo "High latency alert detected for $TARGET!"
        echo "Time: $(date)"
        echo "Median latency: $1 ms"
        echo "Threshold: 150 ms"
        echo "This may indicate poor network performance."
    } | mail -s "$SUBJECT" "$EMAIL_TO"
    echo "[$(date)] URGENT email sent to $EMAIL_TO" >> "$LOG_FILE"
}

# === Main Loop ===

echo "[$(date)] Starting ping monitoring for $TARGET" | tee -a "$LOG_FILE"

while true; do
    output=$(ping -c 1 -W 2 $TARGET)
    total_pings=$((total_pings + 1))

    if echo "$output" | grep -q "time="; then
        successful_pings=$((successful_pings + 1))
        ms=$(echo "$output" | grep -oP 'time=\K[\d.]+' | head -1)
        total_response_time=$(awk "BEGIN { print $total_response_time + $ms }")
        response_times+=("$ms")
    else
        failed_pings=$((failed_pings + 1))
        echo "$(date): Ping to $TARGET failed." >> "$LOG_FILE"
    fi

    # Every 600 pings (~10 min), write summary and check median
    if (( total_pings % 600 == 0 )); then
        write_summary

        median_latency=$(calculate_median)
        if (( $(echo "$median_latency > 150" | bc -l) )); then
            send_urgent_email "$median_latency"
        fi

        response_times=()  # Clear array after each 10-minute check
    fi

    # Regular summary and email every 12 hours
    now=$(date +%s)
    if (( now - last_email_sent >= 43200 )); then
        write_summary
        send_email_summary
        last_email_sent=$now
    fi

    sleep 1
done
