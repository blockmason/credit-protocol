var h = require("./helpers/helpers");

const should = require('chai')
          .use(require('chai-as-promised'))
          .use(require('chai-bignumber')(h.BigNumber))
          .should();

const FriendData = artifacts.require('./FriendData.sol');

contract('FriendData', function([admin1, admin2, parent, p1, p2]) {
    const id1 = "id1";
    const id2 = "id2";
    const ucacMain = "ucacMain";

    before(async function() {
        // Advance to the next block to correctly read time in the solidity
        // "now" function interpreted by testrpc
    });

    beforeEach(async function() {
        this.fd = await FriendData.new({from: admin1});
        await this.fd.setAdmin2(admin2, {from: admin1});
        await this.fd.changeParent(parent, {from: admin1});

        //initialize all fields for 2 way relationship to non-defaults
        await this.fd.pushFriendId(ucacMain, id1, id2, {from: parent});
        await this.fd.pushFriendId(ucacMain, id2, id1, {from: parent});
        await this.fd.setFriendIdByIndex(ucacMain, id1, 0, id2, {from: parent});
        await this.fd.setFriendIdByIndex(ucacMain, id2, 0, id1, {from: parent});
        await this.fd.fSetInitialized(ucacMain, id1, id2, true, {from: parent});
        await this.fd.fSetf1Id(ucacMain, id1, id2, id1, {from: parent});
        await this.fd.fSetf2Id(ucacMain, id1, id2, id2, {from: parent});
        await this.fd.fSetIsPending(ucacMain, id1, id2, true, {from: parent});
        await this.fd.fSetIsMutual(ucacMain, id1, id2, true, {from: parent});
        await this.fd.fSetf1Confirmed(ucacMain, id1, id2, true, {from: parent});
        await this.fd.fSetf2Confirmed(ucacMain, id1, id2, true, {from: parent});
    });

    describe("Value setting, getting, and retrieval work", () => {
//        it("has correct values for both directions of relationship", async function() {

  //      });
        it("Only parent contract can call setters", async function() {
            await this.fd.pushFriendId(ucacMain, id1, id2, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.fd.setFriendIdByIndex(ucacMain, id1, 0, id2, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.fd.fSetInitialized(ucacMain, id1, id2, true, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.fd.fSetf1Id(ucacMain, id1, id2, id1, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.fd.fSetf2Id(ucacMain, id1, id2, id2, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.fd.fSetIsPending(ucacMain, id1, id2, true, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.fd.fSetIsMutual(ucacMain, id1, id2, true, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.fd.fSetf1Confirmed(ucacMain, id1, id2, true, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.fd.fSetf2Confirmed(ucacMain, id1, id2, true, {from: p1}).should.be.rejectedWith(h.EVMThrow);
        });
    });
});
