#!/bin/sh
# RunCat Neo — Bitcoin and international gold price metrics.

set -u

outputDirectory="${RUNCAT_OUT_DIR:-$HOME/.runcat}"
marketAPI="${MARKET_API:-https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,pax-gold&vs_currencies=usd}"
outputFile="$outputDirectory/markets.json"

logMsg() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2
}

writeMarketsSnapshot() {
    lastUpdatedDate=$(date -u +%Y-%m-%dT%H:%M:%SZ)
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

fetchMarketData() {
    # 优先尝试通过代理请求
    if response=$(curl -fsS --connect-timeout 5 --max-time 10 --retry 1 "$marketAPI" 2>/dev/null); then
        printf '%s' "$response"
        return 0
    fi

    # 如果走代理失败（例如 Clash 未开启或端口不通），尝试绕过代理直连
    if response=$(curl -fsS --noproxy "*" --connect-timeout 5 --max-time 10 "$marketAPI" 2>/dev/null); then
        printf '%s' "$response"
        return 0
    fi

    return 1
}

# 限制日志大小（超过 500KB 保留最后 100 行）
logFile="$outputDirectory/update-markets.log"
if [ -f "$logFile" ] && [ "$(wc -c < "$logFile" 2>/dev/null || echo 0)" -gt 512000 ]; then
    tail -n 100 "$logFile" > "$logFile.tmp" && mv "$logFile.tmp" "$logFile"
fi

if ! marketResponse=$(fetchMarketData); then
    logMsg "WARNING: Network or proxy unreachable. Keeping existing cached prices."
    # 优雅回退：保留现有缓存并正常退出，防止 launchd 报错
    exit 0
fi

bitcoinPrice=$(extractUsd bitcoin)
goldPrice=$(extractUsd pax-gold)

if [ -z "$bitcoinPrice" ] || [ -z "$goldPrice" ]; then
    logMsg "WARNING: Could not parse market data from response: $marketResponse"
    # 遇到接口限流或非预期内容，保留旧缓存并优雅退出
    exit 0
fi

bitcoinCurrentValue=$(formatPrice "$bitcoinPrice" 2)
goldCurrentValue=$(formatPrice "$goldPrice" 2)

if writeMarketsSnapshot; then
    logMsg "SUCCESS: Updated market prices (BTC: $bitcoinCurrentValue, XAU: $goldCurrentValue)"
else
    logMsg "ERROR: Failed to write markets snapshot"
    exit 1
fi

exit 0
