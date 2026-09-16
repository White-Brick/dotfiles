#!/bin/sh
# RunCat Neo — Bitcoin and international gold price metrics.

set -u

outputDirectory="${RUNCAT_OUT_DIR:-$HOME/.runcat}"
marketAPI="https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,pax-gold&vs_currencies=usd"

writeMarketsSnapshot() {
    lastUpdatedDate=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    outputFile="$outputDirectory/markets.json"
    metricsBarValue="BTC: $bitcoinCurrentValue · XAU: $goldCurrentValue"

    mkdir -p "$outputDirectory" || return 1
    temporaryFile=$(mktemp "$outputDirectory/.runcat-XXXXXX") || return 1
    if ! cat > "$temporaryFile" <<EOF
{
  "title": "Markets",
  "symbol": "chart.line.uptrend.xyaxis",
  "metricsBarValue": "$metricsBarValue",
  "metrics": [
    { "title": "BTC", "formattedValue": "$bitcoinCurrentValue" },
    { "title": "XAU", "formattedValue": "$goldCurrentValue" }
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

extractUsd() {
    printf '%s\n' "$marketResponse" | sed -nE "s/.*\"$1\"[[:space:]]*:[[:space:]]*\\{[^}]*\"usd\"[[:space:]]*:[[:space:]]*([0-9]+(\\.[0-9]+)?).*/\\1/p"
}

formatPrice() {
    awk -v price="$1" -v decimals="$2" '
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

if ! marketResponse=$(curl -fsS --max-time 15 "$marketAPI"); then
    echo "Failed to fetch market prices from CoinGecko" >&2
    exit 1
fi

bitcoinPrice=$(extractUsd bitcoin)
goldPrice=$(extractUsd pax-gold)
result=0

if [ -z "$bitcoinPrice" ]; then
    echo "Failed to extract a Bitcoin price from CoinGecko" >&2
    result=1
else
    bitcoinCurrentValue=$(formatPrice "$bitcoinPrice" 2)
fi
if [ -z "$goldPrice" ]; then
    echo "Failed to extract a PAXG price from CoinGecko" >&2
    result=1
else
    goldCurrentValue=$(formatPrice "$goldPrice" 2)
fi
if [ "$result" -eq 0 ]; then
    writeMarketsSnapshot || result=1
fi
exit "$result"
