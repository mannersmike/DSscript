# DSscript.sh

## Description:
This Bash script is designed for managing Lightning Network channels using the Charge-lnd tool. It provides a set of functions to calculate and update the maximum HTLC (Hold-Time Locked Contract) value based on channel balances, capacity checks, and configurable reduction percentages. The script iterates through a list of Lightning Network node public keys, processes associated channels, and logs relevant information.

## Features:

Automatic calculation and adjustment of max_htlc_msat for optimal channel management.
Configurable channel capacity checks with different thresholds.
Log file management to ensure logs do not exceed a specified size.
Optional --dry-run flag for simulating Charge-lnd operations without making actual changes.

## Dependencies:

jq: Lightweight and flexible command-line JSON processor.
bc: Arbitrary precision calculator language.

## Usage:
```
./DSscript.sh [--dry-run]
```

## Options:
--dry-run: Simulate Charge-lnd operations without making actual changes.

## Configuration:
1. Update paths for LNCLI_PATH, CHARGE_LND_PATH, LOG_FILE, PUBKEY_LIST_FILE in the script.
2. Adjust the R_PERCENT variable for the desired reduction percentage.
3. Schedule a cron job to run DSscript
```
#run DSscript every 30 minutes
*/30 * * * *  /PATH/TO/DSscript.sh
``` 

## Note:
1. Ensure dependencies are installed (jq, bc).
2. Ensure Charge-lnd is installed (https://github.com/accumulator/charge-lnd)
3. Replace placeholder paths in the script with actual paths on your system.
4. make sure the script has the execute permission (chmod +x DSscript.sh)

## License:
This script is licensed under the MIT License.

## Disclaimer:
Use this script at your own risk. Be sure to review and understand the code before executing it.

### Tip
#### Lightning
```
lnbc1pj57facpp5lj52aneqv0hr8udwqv30gqd9tr4m4j35t6309lzf5r2kaxk8jj0qdqqcqzzsxqyz5vqsp56yj5fadhg6wseh6pc84el8fyy4u6gj5vwwrzzccx4jhmeweh99ns9qyyssqtsytgz32zdcdr4tv0y7ll56jxsk5wr9wuuyef7rqttvvlqk5ux4kyrgm2qyfcjh73a2n40cr4vp68err3lwv39r5cfgkkr9k5cmxrwsqtzn26y
```
#### BTC 
```
3HLmxh5WfDQoy6ZwKhhH1mgkj2E7Wchnq4
```
