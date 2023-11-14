# DSscript.sh

## Description:
This Bash script is designed for managing Lightning Network channels using the Charge-lnd tool. 
It provides a set of functions to automatically control the outflow of satoshis in a channel. 
When liquidity of a channel reaches a specified threshold, the script disables the outflow by setting the maximum allowed HTLC (Hold-Time Locked Contract) to 1. 
Also included are a set of functions to calculate and update the maximum HTLC of a channel value based on local balances, total capacity, and configurable reduction percentages.
This adjustment helps optimize the channel's outbound liquidity in an effort to reduce failed route attempts due to insufficient funds. 
The script iterates through a list of Lightning Network node public keys, processes associated channels, and logs relevant information.

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

## Note:
1. Ensure dependencies are installed (jq, bc).
2. Ensure Charge-lnd is installed (https://github.com/accumulator/charge-lnd)
3. Replace placeholder paths in the script with actual paths on your system.
4. make sure the script has the execute permission (chmod +x DSscript.sh)

## License:
This script is licensed under the MIT License.

## Disclaimer:
Use this script at your own risk. Be sure to review and understand the code before executing it.

