exports.EVMThrow = 'invalid opcode';

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
