var h = require("./helpers/helpers");

const should = require('chai')
          .use(require('chai-as-promised'))
          .use(require('chai-bignumber')(h.BigNumber))
          .should();

const FriendData = artifacts.require('./FriendData.sol');

const ucacId1 = web3.fromAscii("hi");
const ucacId2 = web3.fromAscii("yo");

contract('FriendCreationTest', function([p1, p2, p3, p4, p5]) {

    before(async function() {
    });

    beforeEach(async function() {
        this.friendData = await FriendData.new({from: p5});
    });

    describe("Friend Creation", () => {
        it("allows two parties to sign a message and create a friendship", async function() {
            let data = ucacId1;
            let sig1 = web3.eth.sign(p1, ucacId1);
            sig1 = sig1.substr(2, sig1.length);
            let r1 = '0x' + sig1.substr(0, 64);
            let s1 = '0x' + sig1.substr(64, 64);
            let v1 = web3.toDecimal(sig1.substr(128, 2)) + 27;

            let a = await this.friendData.initFriendship(ucacId1, p1, p2, ucacId1, r1, s1, v1, r1, s1, v1);
            console.log(a);
        });
    });

});
