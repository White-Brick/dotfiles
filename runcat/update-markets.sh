#!/bin/sh
# RunCat Neo — Bitcoin and international gold price metrics.

set -u

outputDirectory="${RUNCAT_OUT_DIR:-$HOME/.runcat}"
bitcoinAPI="https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd"
goldAPI="https://xaus.com/api/v1/spot"
goldFetched=0
goldResponse=""

writeSnapshot() {
    outputFile=$1
    title=$2
    symbol=$3
    metricsBarValue=$4
    metricTitle=$5
    currentValue=$6
    lastUpdatedDate=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    mkdir -p "$outputDirectory" || return 1
    temporaryFile=$(mktemp "$outputDirectory/.runcat-XXXXXX") || return 1
    if ! cat > "$temporaryFile" <<EOF
{
  "title": "$title",
  "symbol": "$symbol",
  "metricsBarValue": "$metricsBarValue",
  "metrics": [
    { "title": "$metricTitle", "formattedValue": "$currentValue" }
  ],
  "lastUpdatedDate": "$lastUpdatedDate"
}
EOF
    then
        rm -f "$temporaryFile"
        return 1
    fi
    if ! mv "$temporaryFile" "$outputFile"; then
        rm -f "$temporaryFile"
        return 1
    fi
}

fetchGold() {
    if [ "$goldFetched" -eq 1 ]; then
        return 0
    fi
    if ! goldResponse=$(curl -fsS --max-time 15 "$goldAPI"); then
        echo "Failed to fetch market prices from XAUS" >&2
        return 1
    fi
    goldFetched=1
}

updateBitcoin() {
    bitcoinPrice=""
    if bitcoinResponse=$(curl -fsS --max-time 15 "$bitcoinAPI"); then
        bitcoinPrice=$(printf '%s\n' "$bitcoinResponse" | sed -nE 's/.*"usd"[[:space:]]*:[[:space:]]*([0-9]+(\.[0-9]+)?).*/\1/p')
    else
        echo "CoinGecko unavailable; trying the XAUS Bitcoin fallback" >&2
    fi
    if [ -z "$bitcoinPrice" ] && fetchGold; then
        bitcoinPrice=$(printf '%s\n' "$goldResponse" | sed -nE 's/.*"btc_usd"[[:space:]]*:[[:space:]]*([0-9]+(\.[0-9]+)?).*/\1/p')
    fi
    if [ -z "$bitcoinPrice" ]; then
        echo "Failed to extract a Bitcoin price from CoinGecko or XAUS" >&2
        return 1
    fi

    bitcoinBarValue=$(awk -v price="$bitcoinPrice" 'BEGIN {
        if (price >= 1000000) printf "$%.2fM", price / 1000000
        else if (price >= 1000) printf "$%.1fK", price / 1000
        else printf "$%.2f", price
    }')
    bitcoinCurrentValue=$(awk -v price="$bitcoinPrice" 'BEGIN { printf "$%.2f", price }')
    writeSnapshot "$outputDirectory/bitcoin.json" "Bitcoin" "bitcoinsign" \
        "$bitcoinBarValue" "Current" "$bitcoinCurrentValue"
}

formatGold() {
    goldPrice=$1
    goldDecimals=$2
    awk -v price="$goldPrice" -v decimals="$goldDecimals" '
        function addCommas(value, parts, count, integer, output) {
            count = split(value, parts, ".")
            integer = parts[1]
            output = ""
            while (length(integer) > 3) {
                output = "," substr(integer, length(integer) - 2) output
                integer = substr(integer, 1, length(integer) - 3)
            }
            return integer output (count > 1 ? "." parts[2] : "")
        }
        BEGIN { printf "$%s", addCommas(sprintf("%.*f", decimals, price)) }
    '
}

updateGold() {
    if ! fetchGold; then
        return 1
    fi
    goldState=$(printf '%s\n' "$goldResponse" | sed -nE 's/.*"status"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p')
    if [ "$goldState" != "fresh" ]; then
        echo "XAUS gold price is not fresh; keeping the previous snapshot" >&2
        return 1
    fi
    goldPrice=$(printf '%s\n' "$goldResponse" | sed -nE 's/.*"spot_usd_oz"[[:space:]]*:[[:space:]]*([0-9]+(\.[0-9]+)?).*/\1/p')
    if [ -z "$goldPrice" ]; then
        echo "Failed to extract the XAU/USD spot price from the XAUS response" >&2
        return 1
    fi

    goldBarValue=$(formatGold "$goldPrice" 0)
    goldCurrentValue="$(formatGold "$goldPrice" 2)/oz"
    writeSnapshot "$outputDirectory/gold.json" "Gold" "dollarsign.circle" \
        "$goldBarValue" "Spot" "$goldCurrentValue"
}

result=0
updateBitcoin || result=1
updateGold || result=1
exit "$result"
