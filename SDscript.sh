#!/bin/bash
# Usage: ./DSscript.sh [--dry-run]

# Define file paths
LNCLI_PATH="/PATH/TO/lncli"
CHARGE_LND_PATH="/PATH/TO/charge-lnd"
PUBKEY_LIST_FILE="/PATH/TO/pubkey_list.txt"
LOG_FILE="/PATH/TO/htlc-updates.log"
MAX_LOG=100

# Define variable
R_PERCENT=5
DEBUGMODE=0  # 0 for disabled, 1 for enabled

# Initialize an array to store the results
declare -a results

# Function to create log array
log_to_file() {
    # Limiting peer alias to 20 characters and removing spaces.
    local peer="${peer_alias:0:20}"
    local peer="${peer// /_}"
    local formatted_capacity=$(printf "%'d" "$capacity")
    local formatted_local_balance=$(printf "%'d" "$local_balance")
    local current_max_htlc=$((current_max_htlc_msat / 1000))
    local formatted_current_max_htlc=$(printf "%'d" "$current_max_htlc")
    local formatted_rounded_max_htlc=$(printf "%'d" "$rounded_max_htlc")
    # Build a string with the formatted result
    result_str="$peer $formatted_capacity $formatted_local_balance $formatted_current_max_htlc $formatted_rounded_max_htlc"
    # Append the result to the array
    results+=("$result_str")
}

# Function to calculate max_htlc_msat reduction and rounding down to nearest 250000
calculate_max_htlc_msat() {
    local balance=$1
    local reduction_percentage=$R_PERCENT
    local max_htlc_msat=$((balance - balance * reduction_percentage / 100))
    local rounded_max_htlc_msat=$(( (max_htlc_msat / 250000) * 250000 ))
    echo ${rounded_max_htlc_msat}000
}

# Function to perform capacity check and set disable threshold percentage
capacity_check() {
    local capacity=$1
    if [[ $capacity -ge 1 && $capacity -le 1899999 ]]; then
        minpercentage=10
    elif [[ $capacity -ge 1900000 && $capacity -le 7900000 ]]; then
        minpercentage=8
    elif [[ $capacity -ge 7900001 && $capacity -le 9900000 ]]; then
        minpercentage=6
    elif [[ $capacity -ge 9900001 && $capacity -le 15900000 ]]; then
        minpercentage=5
    elif [[ $capacity -ge 15900001 && $capacity -le 49900000 ]]; then
        minpercentage=4
    elif [[ $capacity -ge 49900001 && $capacity -le 99900000 ]]; then
        minpercentage=3
    else
        minpercentage=1
    fi
    if [ $DEBUGMODE -eq 1 ]; then
        echo "[ DS ] Minimum acceptable percentage for capacity $capacity is $minpercentage%" >> $LOG_FILE
    fi
}

# Function to check max_htlc_msat
max_htlc_check() {
    local minpercentage=$1
    local percentage=$2
    local current_max_htlc_msat=$3
    if [[ $percentage -le $minpercentage ]]; then
        if [[ $current_max_htlc_msat -eq 1000 ]]; then
                    if [ $DEBUGMODE -eq 1 ]; then
                echo -e "\e[90m[\e[0m\e[94m \e[1mDS \e[0m\e[90m]\e[0m max_htlc_msat already set to \e[1m1000\e[0m. Moving on to next channel."
                echo -e "\e[90m[\e[0m\e[94m \e[1mDS \e[0m\e[90m]\e[0m "
                echo -e "[ DS ] max_htlc_msat already set to 1000. Moving on to next channel." >> $LOG_FILE
                fi
            return
        else
            max_htlc_msat=1000
                        if [ $DEBUGMODE -eq 1 ]; then
                echo -e "\e[90m[\e[0m\e[94m \e[1mDS \e[0m\e[90m]\e[0m Creating Charge-lnd cfg for \e[1m$peer_alias\e[0m. setting max_htlc_msat to \e[1m1000\e[0m"
                echo -e "[ DS ] Creating Charge-lnd cfg for $peer_alias. setting max_htlc_msat to 1000" >> $LOG_FILE
                        fi
            create_temp_config
        fi
    elif [[ $(calculate_max_htlc_msat $local_balance) -eq $current_max_htlc_msat ]]; then
        max_htlc_msat=$(calculate_max_htlc_msat $local_balance)
                if [ $DEBUGMODE -eq 1 ]; then
             echo -e "\e[90m[\e[0m\e[94m \e[1mDS \e[0m\e[90m]\e[0m max_htlc_msat already set to \e[1m$max_htlc_msat\e[0m. Moving on to next channel."
             echo -e "\e[90m[\e[0m\e[94m \e[1mDS \e[0m\e[90m]\e[0m "
             echo -e "[ DS ] max_htlc_msat already set to $max_htlc_msat. Moving on to next channel." >> $LOG_FILE
                fi
        return
    else
        max_htlc_msat=$(calculate_max_htlc_msat $local_balance)
                if [ $DEBUGMODE -eq 1 ]; then
            echo -e "\e[90m[\e[0m\e[94m \e[1mDS \e[0m\e[90m]\e[0m Creating Charge-lnd cfg for \e[1m$peer_alias\e[0m. setting max_htlc_msat to \e[1m$max_htlc_msat\e[0m"
            echo -e "[ DS ] Creating Charge-lnd cfg for $peer_alias. setting max_htlc_msat to $max_htlc_msat" >> $LOG_FILE
                fi
        create_temp_config
    fi
}

# Function to create temporary config file
create_temp_config() {
    if [ $DEBUGMODE -eq 1 ]; then
        echo "Creating Charge-lnd config for $peer_alias : $chan_id. setting max_htlc_msat to $max_htlc_msat" >> $LOG_FILE
        echo "[ DS ] " >> $LOG_FILE
    fi
    temp_config="/tmp/charge-lnd-config-$chan_id.cfg"
    if [ -f "$temp_config" ]; then
            if [ $DEBUGMODE -eq 1 ]; then
            echo -e "\e[90m[\e[0m\e[94m \e[1mDS \e[0m\e[90m]\e[0m Removing old/existing config file: $temp_config"
                        echo -e "[ DS ] Removing old/existing config file: $temp_config" >> $LOG_FILE
                fi
        rm "$temp_config"
    fi
    echo "[set-max-htlc]" >> $temp_config
    echo "chan.id = $chan_id" >> $temp_config
    echo "strategy = static" >> $temp_config
    echo "max_htlc_msat = $max_htlc_msat" >> $temp_config
    if [ $DEBUGMODE -eq 1 ]; then
            echo -e "\e[90m[\e[0m\e[94m \e[1mDS \e[0m\e[90m]\e[0m Peer Alias: \e[1m$peer_alias\e[0m, Capacity: \e[1m$capacity\e[0m, Local Balance: \e[1m$local_balance\e[0m, Old max_htlc_msat: \e[1m$current_max_htlc_msat\e[0m, New max_htlc_msat: \e[1m$max_htlc_msat\e[0m"
            echo -e "[ DS ] Peer Alias: $peer_alias, Capacity: $capacity, Local Balance: $local_balance, Old max_htlc_msat: $current_max_htlc_msat, New max_htlc_msat: $max_htlc_msat" >> $LOG_FILE
    fi
    # Add --dry-run option if DRY_RUN_FLAG is true
    if [ "$DRY_RUN_FLAG" = true ]; then
        if [ $DEBUGMODE -eq 1 ]; then
                echo -e "[ DS ] Charge-lnd" >> $LOG_FILE
                    echo -e " " >> $LOG_FILE
            $CHARGE_LND_PATH --dry-run -v -c $temp_config >> $LOG_FILE 2>&1
            echo -e " " >> $LOG_FILE
        else
            $CHARGE_LND_PATH --dry-run -v -c $temp_config >> /dev/null 2>&1
        fi
    else
        if [ $DEBUGMODE -eq 1 ]; then
                        echo -e "[ DS ] Charge-lnd" >> $LOG_FILE
                    echo -e " " >> $LOG_FILE
            $CHARGE_LND_PATH -v -c $temp_config >> $LOG_FILE 2>&1
            echo -e " " >> $LOG_FILE
        else
            $CHARGE_LND_PATH -v -c $temp_config >> /dev/null 2>&1
        fi
    fi
        if [ $DEBUGMODE -eq 1 ]; then
        echo -e "\e[90m[\e[0m\e[94m \e[1mDS \e[0m\e[90m]\e[0m Clean up temporary config files..."
        echo -e "\e[90m[\e[0m\e[94m \e[1mDS \e[0m\e[90m]\e[0m "
        echo -e "[ DS ] Clean up temporary config files..." >> $LOG_FILE
        fi
        rm $temp_config
    local rounded_max_htlc=$(( (max_htlc_msat / 250000) * 250000 / 1000))
    log_to_file "$peer_alias" "$capacity" "$local_balance" "$current_max_htlc_msat" "$rounded_max_htlc"
}

# Function to preprocess channel data, checking for multiple chan_id's
preprocess_channel() {
    local pubkey=$1
    local channel_info_list=$($LNCLI_PATH listchannels | jq --arg pubkey "$pubkey" '.channels[] | select(.remote_pubkey == $pubkey)')
    while read -r chan_id; do
        process_channel "$chan_id"
    done <<< "$(echo "$channel_info_list" | jq -r '.chan_id')"
}

# Function to process channel
process_channel() {
    local chan_id=$1
    local channel_info=$(echo "$($LNCLI_PATH listchannels)" | jq '.channels[] | select(.chan_id == '\"$chan_id\"')')
    if [ $DEBUGMODE -eq 1 ]; then
        echo "[ DS ] " >> $LOG_FILE
        echo "[ DS ] " >> $LOG_FILE
    fi
        echo "[ DS ] Processing $pubkey..." >> $LOG_FILE
        if [ $DEBUGMODE -eq 1 ]; then
            echo >> $LOG_FILE
            echo "Channel Info: $channel_info" >> $LOG_FILE
            echo >> $LOG_FILE
        fi
    # Extract relevant data
    peer_alias=$(echo "$channel_info" | jq -r '.peer_alias')
    capacity=$(echo "$channel_info" | jq -r '.capacity')
    local_balance=$(echo "$channel_info" | jq -r '.local_balance')
    # Use chan_id to find current max_htlc_msat
    local getchaninfo="$($LNCLI_PATH getchaninfo $chan_id)"
    local node1_pub=$(echo $getchaninfo | jq -r '.node1_pub')
    local node2_pub=$(echo $getchaninfo | jq -r '.node2_pub')
    if [ "$pubkey" == "$node1_pub" ]; then
        current_max_htlc_msat=$(echo $getchaninfo | jq -r '.node2_policy.max_htlc_msat')
    elif [ "$pubkey" == "$node2_pub" ]; then
        current_max_htlc_msat=$(echo $getchaninfo | jq -r '.node1_policy.max_htlc_msat')
    else
        # Handle the case where the pubkey doesn't match either node1_pub or node2_pub
    if [ $DEBUGMODE -eq 1 ]; then
            echo -e "\e[90m[\e[0m\e[94m \e[1mDS \e[0m\e[90m]\e[0m Error: Pubkey not found in chan_id information"
        echo "[ DS ] Error: Pubkey not found in chan_id information" >> $LOG_FILE
        echo "[ DS ] " >> $LOG_FILE
    fi
    exit 1
    fi
    if [ $DEBUGMODE -eq 1 ]; then
        echo "[ DS ] Channel max_htlc_msat Info: $current_max_htlc_msat" >> $LOG_FILE
    fi
    percentage=$(printf "%.0f" "$(bc <<< "scale=2; ($local_balance / $capacity) * 100")")
        if [ $DEBUGMODE -eq 1 ]; then
        echo -e "\e[90m[\e[0m\e[94m \e[1mDS \e[0m\e[90m]\e[0m \e[1m$peer_alias\e[0m \ \e[1m$pubkey\e[0m \ \e[1m$chan_id\e[0m"
        echo -e "\e[90m[\e[0m\e[94m \e[1mDS \e[0m\e[90m]\e[0m Capacity: \e[1m$capacity\e[0m \ Local Balance: \e[1m$local_balance ($percentage%)\e[0m \ Current max_htlc_msat: \e[1m$current_max_htlc_msat\e[0m"
        echo -e "[ DS ] $peer_alias \ $pubkey \ $chan_id" >> $LOG_FILE
        echo -e "[ DS ] Capacity: $capacity \ Local Balance: $local_balance ($percentage%) \ Current max_htlc_msat: $current_max_htlc_msat" >> $LOG_FILE
        fi
    capacity_check $capacity
    max_htlc_check $minpercentage $percentage $current_max_htlc_msat
}

# Function to clean up logs after 100MB
check_and_delete_log_file() {
    local log_file=$1
    local max_size_mb=$MAX_LOG
    local max_size_bytes=$((max_size_mb * 1024 * 1024))
    if [[ -f $log_file ]]; then
        local file_size=$(stat -c%s $log_file)
        if [[ $file_size -gt $max_size_bytes ]]; then
            if [ $DEBUGMODE -eq 1 ]; then
                echo -e "\e[90m[\e[0m\e[94m \e[1mDS \e[0m\e[90m]\e[0m Log file size exceeds $max_size_mb MB. Deleting..."
                echo -e "[ DS ] Log file size exceeds $max_size_mb MB. Deleting..." >> $LOG_FILE
            fi
            rm $log_file
            touch $log_file
            echo -e "[ DS ] log file created $(date)" >> $log_file
            echo -e "[ DS ]" >> $log_file
            if [ $DEBUGMODE -eq 1 ]; then
               echo -e "\e[90m[\e[0m\e[94m \e[1mDS \e[0m\e[90m]\e[0m Log file deleted and recreated."
               echo -e "[ DS ] Log file deleted and recreated." >> $LOG_FILE
            fi
        fi
    else
        if [ $DEBUGMODE -eq 1 ]; then
            echo -e "\e[90m[\e[0m\e[94m \e[1mDS \e[0m\e[90m]\e[0m Log file not found."
            echo -e "[ DS ] Log file not found." >> $LOG_FILE
            echo -e "[ DS ] " >> $LOG_FILE
        fi
        touch $log_file
        echo -e "[ DS ] log file created $(date)" >> $LOG_FILE
        echo -e "[ DS ] " >> $LOG_FILE
    fi
}

# Parse command line options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN_FLAG=true
            shift
            ;;
        *)
            echo -e "\e[90m[\e[0m\e[94m \e[1mDS \e[0m\e[90m]\e[0m Unknown option: $1"
                        echo -e "[ DS ] Unknown option: $1" >> $LOG_FILE
            exit 1
            ;;
    esac
done

# Iterate through each pubkey in the list
while IFS= read -r pubkey; do
    # Skip lines starting with #
    if [[ $pubkey == \#* ]]; then
        continue
    fi
    check_and_delete_log_file "$LOG_FILE"
    pubkey=$pubkey
    preprocess_channel $pubkey
done < "$PUBKEY_LIST_FILE"

# Check if results array is not empty
if [ ${#results[@]} -gt 0 ]; then
    # Display all results at once
    # Print all results
    echo -e "\e[90m[\e[0m\e[94m \e[1mDS \e[0m\e[90m]\e[0m ┌──────────────────────┬──────────────────────┬──────────────────────┬──────────────────────┬──────────────────────┐"
    echo -e "\e[90m[\e[0m\e[94m \e[1mDS \e[0m\e[90m]\e[0m │ Peer Alias           │ Capacity             │ Local Balance        │ Old Max HTLC (sats)  │ New Max HTLC (sats)  │"
    echo -e "\e[90m[\e[0m\e[94m \e[1mDS \e[0m\e[90m]\e[0m ╞══════════════════════╪══════════════════════╪══════════════════════╪══════════════════════╪══════════════════════╡"
    echo -e "[ DS ] " >> $LOG_FILE
    echo -e "[ DS ] ┌──────────────────────┬──────────────────────┬──────────────────────┬──────────────────────┬──────────────────────┐" >> $LOG_FILE
    echo -e "[ DS ] │ Peer Alias           │ Capacity             │ Local Balance        │ Old Max HTLC (sats)  │ New Max HTLC (sats)  │" >> $LOG_FILE
    echo -e "[ DS ] ╞══════════════════════╪══════════════════════╪══════════════════════╪══════════════════════╪══════════════════════╡" >> $LOG_FILE
    for result in "${results[@]}"; do
        printf "\e[90m[\e[0m\e[94m \e[1mDS \e[0m\e[90m]\e[0m │ %-20s │ %-20s │ %-20s │ %-20s │ %-20s │\n" $result
        printf "[ DS ] │ %-20s │ %-20s │ %-20s │ %-20s │ %-20s │\n" $result >> $LOG_FILE
    done
    echo -e "\e[90m[\e[0m\e[94m \e[1mDS \e[0m\e[90m]\e[0m └──────────────────────┴──────────────────────┴──────────────────────┴──────────────────────┴──────────────────────┘"
    echo -e "\e[90m[\e[0m\e[94m \e[1mDS \e[0m\e[90m]\e[0m Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "[ DS ] └──────────────────────┴──────────────────────┴──────────────────────┴──────────────────────┴──────────────────────┘" >> $LOG_FILE
    echo -e "[ DS ] Timestamp: $(date '+%Y-%m-%d %H:%M:%S')" >> $LOG_FILE

fi
    echo -e "[ DS ] Jobs done." >> $LOG_FILE
    echo -e "[ DS ] " >> $LOG_FILE
