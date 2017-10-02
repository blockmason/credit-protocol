exports.EVMThrow = 'invalid opcode';

const BigNumber = web3.BigNumber;
const toWei     = web3.toWei;
const fromWei   = web3.fromWei;

exports.BigNumber = BigNumber;
exports.toWei = toWei;
exports.fromWei = fromWei;

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
