exports.EVMThrow = 'VM Exception while processing transaction: revert';

const testMemo = web3.fromAscii("test1")

exports.b2s = function(bytes) {
    var s = "";
    for(var i=2; i<bytes.length; i+=2) {
        var num = parseInt(bytes.substring(i, i+2), 16);
        if (num == 0) break;
        var char = String.fromCharCode(num);
        s += char;
    }
    return s;
};

// Increases testrpc time by the passed duration in seconds
const increaseTime = function(duration) {
    const id = Date.now();

    return new Promise((resolve, reject) => {
        web3.currentProvider.sendAsync({
            jsonrpc: '2.0',
            method: 'evm_increaseTime',
            params: [duration],
            id: id,
        }, err1 => {
            if (err1) return reject(err1)

            web3.currentProvider.sendAsync({
                jsonrpc: '2.0',
                method: 'evm_mine',
                id: id + 1,
            }, (err2, res) => {
                return err2 ? reject(err2) : resolve(res);
            });
        });
    });
};
exports.increaseTime = increaseTime;

/**
 * Beware that due to the need of calling two separate testrpc methods and rpc
 * calls overhead it's hard to increase time precisely to a target point so
 * design your test to tolerate small fluctuations from time to time.
 *
 * @param target time in seconds
 */
exports.increaseTimeTo = function(target) {
    let now = latestTime();
    if (target < now) throw Error(`Cannot increase current time(${now}) to a moment in the past(${target})`);
    let diff = target - now;
    return increaseTime(diff);
};

exports.duration = {
    seconds: function(val) { return val},
    minutes: function(val) { return val * this.seconds(60) },
    hours:   function(val) { return val * this.minutes(60) },
    days:    function(val) { return val * this.hours(24) },
    weeks:   function(val) { return val * this.days(7) },
    years:   function(val) { return val * this.days(365) }
};

exports.advanceBlock = function() {
    return new Promise((resolve, reject) => {
        web3.currentProvider.sendAsync({
            jsonrpc: '2.0',
            method: 'evm_mine',
            id: Date.now()
        }, (err, res) => {
            return err ? reject(err) : resolve(res);
        });
    });
};


const latestTime = function() {
    return web3.eth.getBlock('latest').timestamp;
};
exports.latestTime = latestTime;

function sign(signer, content) {
    let contentHash = web3.sha3(content, {encoding: 'hex'});
    let sig = web3.eth.sign(signer, contentHash, {encoding: 'hex'});
    sig = sig.substr(2, sig.length);

    let res = {};
    res.r = "0x" + sig.substr(0, 64);
    res.s = "0x" + sig.substr(64, 64);
    res.v = web3.toDecimal("0x" + sig.substr(128, 2));
    if (res.v < 27) res.v += 27;
    res.v = bignumToHexString(web3.toBigNumber(res.v));

    return res;
}
exports.sign = sign;

function bignumToHexString(num) {
    const a = num.toString(16);
    return "0x" + '0'.repeat(64 - a.length) + a;
}
exports.bignumToHexString = bignumToHexString;

function fillBytes32(ascii) {
    // 66 instead of 64 to account for the '0x' prefix
    return ascii + '0'.repeat(66 - ascii.length);
}
exports.fillBytes32 = fillBytes32;

function stripHex(addr) {
    return addr.substr(2, addr.length);
}
exports.stripHex = stripHex;

async function makeTransaction(cp, ucacAddr, creditor, debtor, _amount) {
    let nonce = creditor < debtor ? await cp.nonces(creditor, debtor) : await cp.nonces(debtor, creditor);
    nonce = bignumToHexString(nonce);
    let amount = bignumToHexString(_amount);
    let content = creditHash(ucacAddr, creditor, debtor, amount, nonce);
    let sig1 = sign(creditor, content);
    let sig2 = sign(debtor, content);
    let txReciept = await cp.issueCredit( ucacAddr, creditor, debtor, amount
                                   , [ sig1.r, sig1.s, sig1.v ]
                                   , [ sig2.r, sig2.s, sig2.v ]
                                   , testMemo, {from: creditor});
    return txReciept;
}
exports.makeTransaction = makeTransaction;

function creditHash(ucacAddr, p1, p2, amount, nonce) {
    return [ucacAddr, p1, p2, amount, nonce].map(stripHex).join("")
}
exports.creditHash = creditHash;
