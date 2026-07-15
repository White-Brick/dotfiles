#!/bin/sh

set -eu

temporaryDirectory=$(mktemp -d)
trap 'rm -rf "$temporaryDirectory"' 0

mkdir -p "$temporaryDirectory/bin"
cat > "$temporaryDirectory/bin/curl" <<'EOF'
#!/bin/sh
case "$*" in
    *api.coingecko.com*)
        if [ "${MARKET_TEST_FAILURE:-}" = "bitcoin" ]; then
            printf '%s\n' '{}'
        else
            printf '%s\n' '{"bitcoin":{"usd":64547}}'
        fi
        ;;
    *xaus.com*)
        case "${MARKET_TEST_FAILURE:-}" in
            bitcoin)
                printf '%s\n' '{"status":"fresh","spot_usd_oz":4025}'
                ;;
            gold)
                printf '%s\n' '{"status":"stale","spot_usd_oz":4025,"btc_usd":64547}'
                ;;
            *)
                printf '%s\n' '{"status":"fresh","spot_usd_oz":4025,"btc_usd":64547}'
                ;;
        esac
        ;;
    *)
        exit 1
        ;;
esac
EOF
chmod +x "$temporaryDirectory/bin/curl"

PATH="$temporaryDirectory/bin:$PATH" \
    RUNCAT_OUT_DIR="$temporaryDirectory/output" \
    "$(dirname "$0")/update-markets.sh"

marketsFile="$temporaryDirectory/output/markets.json"
test "$(plutil -extract title raw -o - "$marketsFile")" = "Markets"
test "$(plutil -extract metricsBarValue raw -o - "$marketsFile")" = "BTC \$64.5K · XAU \$4,025"
test "$(plutil -extract metrics.0.title raw -o - "$marketsFile")" = "Bitcoin"
test "$(plutil -extract metrics.0.formattedValue raw -o - "$marketsFile")" = "\$64547.00"
test "$(plutil -extract metrics.1.title raw -o - "$marketsFile")" = "Gold (XAU)"
test "$(plutil -extract metrics.1.formattedValue raw -o - "$marketsFile")" = "\$4,025.00/oz"

test ! -e "$temporaryDirectory/output/bitcoin.json"
test ! -e "$temporaryDirectory/output/gold.json"

assertFailurePreservesMarkets() {
    failureType=$1
    failureOutput="$temporaryDirectory/$failureType-output"
    mkdir -p "$failureOutput"
    printf '%s\n' '{"title":"Existing markets"}' > "$failureOutput/markets.json"
    previousChecksum=$(cksum < "$failureOutput/markets.json")

    if MARKET_TEST_FAILURE="$failureType" \
        PATH="$temporaryDirectory/bin:$PATH" \
        RUNCAT_OUT_DIR="$failureOutput" \
        "$(dirname "$0")/update-markets.sh" 2>/dev/null
    then
        return 1
    fi

    test "$(cksum < "$failureOutput/markets.json")" = "$previousChecksum"
}

assertFailurePreservesMarkets bitcoin
assertFailurePreservesMarkets gold
