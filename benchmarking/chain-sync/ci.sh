#!/usr/bin/env nix-shell
#!nix-shell -i bash -p yj

if [ $# -lt 1 ]; then
  echo "call: $0 mainnet|testnet"
  exit 1
fi

set -euo pipefail

BASEDIR="$(realpath $(dirname $0))"

# >> cpu time limit in seconds
TIME_LIMIT=$((60*60))

CLUSTER="$1"

LOG_CONFIG="$(yj < $BASEDIR/configuration/log-config-ci.yaml)"

CUSTOM_CONFIG="{nodeConfig = builtins.fromJSON ''$LOG_CONFIG'';}"

nix build --out-link launch_node -f $BASEDIR/../.. scripts.$CLUSTER.node --arg customConfig "$CUSTOM_CONFIG"

rm -rf "./state-node-$CLUSTER"
mkdir "./state-node-$CLUSTER"
cd "./state-node-$CLUSTER"

echo
echo "configuration"
echo "============="
echo "${LOG_CONFIG}"
echo
echo "topology"
echo "========"
TOPOLOGY=`cat ../launch_node | sed -ne 's/.* --topology \([^ ]\+\) .*/\1/p;' | tail -1`
cat "${TOPOLOGY}"
echo
echo

RTS="+RTS -T -I0 -N2 -A16m -RTS"
RTS=""
timeout ${TIME_LIMIT} ../launch_node ${RTS} || true

cd ..

$BASEDIR/analyse-logs.sh | tee benchmark-results.log
