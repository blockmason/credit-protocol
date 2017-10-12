var h = require("./helpers/helpers");

const should = require('chai')
          .use(require('chai-as-promised'))
          .use(require('chai-bignumber')(h.BigNumber))
          .should();

const FriendData = artifacts.require('./FriendData.sol');

const ucacId1 = web3.sha3("hi");
const ucacId2 = web3.sha3("yo");


const sign = function(signer, content) {
    let sig = web3.eth.sign(signer, content, {encoding: 'hex'});
    sig = sig.substr(2, sig.length);

    let res = {};
    res.r = "0x" + sig.substr(0, 64);
    res.s = "0x" + sig.substr(64, 64);
    res.v = web3.toDecimal("0x" + sig.substr(128, 2));

    if (res.v < 27) res.v += 27;

    return res
}

contract('FriendCreationTest', function([p1, p2]) {

    before(async function() {
    });

    beforeEach(async function() {
        this.friendData = await FriendData.new({from: p2});
    });

    describe("Friend Creation", () => {
        it("allows two parties to sign a message and create a friendship", async function() {
            let data = web3.sha3("\x19Ethereum Signed Message:\n32" + ucacId1, {encoding: 'hex'});
            let res = sign(p1, ucacId1);
            console.log(res);
            await this.friendData.initFriendship.sendTransaction(ucacId1, p1, p2, data, res.r, res.s, res.v, {from: p1}); // , r1, s1, v1);
            let a = await this.friendData.initFriendship(ucacId1, p1, p2, data, res.r, res.s, res.v, {from: p1}); //, r1, s1, v1);
            assert(a, "signatures are not correct and friendship was not initialized");
        });
    });

});
