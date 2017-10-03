var h = require("./helpers/helpers");

const should = require('chai')
          .use(require('chai-as-promised'))
          .use(require('chai-bignumber')(h.BigNumber))
          .should();

const FriendData = artifacts.require('./FriendData.sol');

contract('FriendData', function([admin1, admin2, parent, p1, p2]) {
    const id1 = "id1";
    const id2 = "id2";
    const id3 = "id3";
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
        await this.fd.pushFriendId(ucacMain, id1, id3, {from: parent});
        await this.fd.pushFriendId(ucacMain, id3, id1, {from: parent});
        await this.fd.setFriendIdByIndex(ucacMain, id1, 0, id2, {from: parent});
        await this.fd.setFriendIdByIndex(ucacMain, id1, 1, id3, {from: parent});
        await this.fd.setFriendIdByIndex(ucacMain, id2, 0, id1, {from: parent});
        await this.fd.setFriendIdByIndex(ucacMain, id3, 0, id1, {from: parent});
        await this.fd.fSetInitialized(ucacMain, id1, id2, true, {from: parent});
        await this.fd.fSetf1Id(ucacMain, id1, id2, id1, {from: parent});
        await this.fd.fSetf2Id(ucacMain, id1, id2, id2, {from: parent});
        await this.fd.fSetIsPending(ucacMain, id1, id2, true, {from: parent});
        await this.fd.fSetIsMutual(ucacMain, id1, id2, true, {from: parent});
        await this.fd.fSetf1Confirmed(ucacMain, id1, id2, true, {from: parent});
        await this.fd.fSetf2Confirmed(ucacMain, id1, id2, true, {from: parent});
    });

    describe("Parent setting", () => {
        it("Non-admin can't change parent", async function() {
            await this.fd.changeParent(p1, {from: p2}).should.be.rejectedWith(h.EVMThrow);
        });
        it("Admins can change parent", async function() {
            await this.fd.changeParent(p1, {from: admin1}).should.be.fulfilled;
            await this.fd.changeParent(p1, {from: admin2}).should.be.fulfilled;
        });

    });

    describe("Value setting, getting, indices, and retrieval work", () => {
        it("has correct values for both directions of relationship", async function() {
            (await this.fd.numFriends(ucacMain, id1)).valueOf().should.equal("2");
            (await this.fd.numFriends(ucacMain, id2)).valueOf().should.equal("1");
            (await this.fd.numFriends(ucacMain, id3)).valueOf().should.equal("1");
            h.b2s((await this.fd.friendIdByIndex(ucacMain, id1, 0)).valueOf()).should.equal(id2);
            h.b2s((await this.fd.friendIdByIndex(ucacMain, id1, 1)).valueOf()).should.equal(id3);
            (await this.fd.fInitialized(ucacMain, id1, id2)).valueOf().should.equal(true);
            (await this.fd.fInitialized(ucacMain, id2, id1)).valueOf().should.equal(true);
            h.b2s((await this.fd.ff1Id(ucacMain, id1, id2)).valueOf()).should.equal(id1);
            h.b2s((await this.fd.ff1Id(ucacMain, id2, id1)).valueOf()).should.equal(id1);
            h.b2s((await this.fd.ff2Id(ucacMain, id1, id2)).valueOf()).should.equal(id2);
            h.b2s((await this.fd.ff2Id(ucacMain, id2, id1)).valueOf()).should.equal(id2);
            (await this.fd.fIsPending(ucacMain, id1, id2)).valueOf().should.equal(true);
            (await this.fd.fIsPending(ucacMain, id2, id1)).valueOf().should.equal(true);
            (await this.fd.fIsMutual(ucacMain, id1, id2)).valueOf().should.equal(true);
            (await this.fd.fIsMutual(ucacMain, id2, id1)).valueOf().should.equal(true);
            (await this.fd.ff1Confirmed(ucacMain, id1, id2)).valueOf().should.equal(true);
            (await this.fd.ff1Confirmed(ucacMain, id2, id1)).valueOf().should.equal(true);
            (await this.fd.ff2Confirmed(ucacMain, id1, id2)).valueOf().should.equal(true);
            (await this.fd.ff2Confirmed(ucacMain, id2, id1)).valueOf().should.equal(true);
        });

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
