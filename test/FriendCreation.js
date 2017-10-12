var h = require("./helpers/helpers");

const should = require('chai')
          .use(require('chai-as-promised'))
          .use(require('chai-bignumber')(h.BigNumber))
          .should();

const FriendData = artifacts.require('./FriendData.sol');

const ucacId1 = web3.sha3("hi");
const ucacId2 = web3.sha3("yo");


const sign = function(signer, content) {
    let contentHash = web3.sha3(content, {encoding: 'hex'});
    console.log("content hash: " + contentHash);
    let sig = web3.eth.sign(signer, contentHash, {encoding: 'hex'});
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
            let content1 = ucacId1 + p2.substr(2, p2.length);
            let sig1 = sign(p1, content1);
            let content2 = ucacId1 + p1.substr(2, p1.length);
            let sig2 = sign(p2, content2);
            await this.friendData.initFriendship.sendTransaction(ucacId1, p1, p2, sig1.r, sig1.s, sig1.v, sig2.r, sig2.s, sig2.v, {from: p1});
            let a = await this.friendData.initFriendship(ucacId1, p1, p2, sig1.r, sig1.s, sig1.v, sig2.r, sig2.s, sig2.v, {from: p1});
            assert(a, "signatures are not correct and friendship was not initialized");
        });
    });

});
