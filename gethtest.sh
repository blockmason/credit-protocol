#!/bin/bash
function cleanup {
    kill -9 $geth_pid
    rm -rf geth
}

trap cleanup EXIT

rm -rf build
mkdir geth && mkdir geth/privchain
cat << EOF > geth/genesis.json
{
    "config": {
        "chainId": 88888,
        "homesteadBlock": 0,
        "eip155Block": 0,
        "eip158Block": 0
    },
    "coinbase" : "0x0000000000000000000000000000000000000000",
    "difficulty" : "0x1",
    "extraData" : "0x00",
    "gasLimit" : "0x47e7c5",
    "nonce" : "0x0000000000000042",
    "mixhash" : "0x0000000000000000000000000000000000000000000000000000000000000000",
    "parentHash" : "0x0000000000000000000000000000000000000000000000000000000000000000",
    "timestamp" : "0x00",
    "alloc" : {
        "198e13017d2333712bd942d8b028610b95c363da": {"balance": "888888888888888888888888888888888888888"},
        "8c12aab5ffbe1f95b890f60832002f3bbc6fa4cf": {"balance": "888888888888888888888888888888888888888"}
    }
}
EOF

privkeys=("7231a774a538fce22a329729b03087de4cb4a1119494db1c10eae3bb491823e7" "b217205550c6011141e3580142ac43d7d41d217102f30e816eb36b70727e292e")

pubkeys=("198e13017d2333712bd942d8b028610b95c363da" "8c12aab5ffbe1f95b890f60832002f3bbc6fa4cf")

geth --datadir geth/privchain init geth/genesis.json

geth --port 3001 --networkid 58342 --nodiscover --datadir="geth/privchain" --maxpeers=0 \
     --rpc --rpcport 8548 --rpcaddr 127.0.0.1 --rpccorsdomain "*" --rpcapi "eth,net,web3,personal" --mine --minerthreads=1 --etherbase "0x198e13017d2333712bd942d8b028610b95c363da" &
geth_pid=$!

sleep 1

for i in "${privkeys[@]}"
do
    geth --datadir geth/privchain --password <(echo "pass") account import <(echo $i)
done

sleep 1

# unlocking accounts
a='{"jsonrpc":"2.0","method":"personal_unlockAccount","params":["'
c='", "pass", 0],"id":67}'
for i in "${pubkeys[@]}"
do
    b="0x$i"
    curl -X POST --data "$a$b$c" http://localhost:8548
done

# use this command to access local blockchain's geth console:
# `geth attach ipc:./geth/privchain/geth.ipc`

# the primary account should already be unlocked and have plenty of eth:
# ```
#   > eth.getBalance(eth.accounts[0])
#   8.88893888888888888888888e+23
# ```

truffle test --network geth $1
wait
