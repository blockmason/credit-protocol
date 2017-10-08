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
    const zero = new h.BigNumber(0);
    const one = new h.BigNumber(1);
    const two = new h.BigNumber(2);
    const three = new h.BigNumber(3);
    const four = new h.BigNumber(4);

    before(async function() {
        // Advance to the next block to correctly read time in the solidity
        // "now" function interpreted by testrpc
    });

    beforeEach(async function() {
        this.fd = await FriendData.new({from: admin1});
        await this.fd.setAdmin2(admin2, {from: admin1});
        await this.fd.changeParent(parent, {from: admin1});
    });

    describe("Visibility restrictions", () => {

        // onlyAdmin modifier
        it("Non-admin can't change parent", async function() {
            await this.fd.changeParent(p1, {from: p2}).should.be.rejectedWith(h.EVMThrow);
        });
        it("Admins can change parent", async function() {
            await this.fd.changeParent(p1, {from: admin1}).should.be.fulfilled;
            await this.fd.changeParent(p1, {from: admin2}).should.be.fulfilled;
        });

        // onlyParent modifier
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
            await this.fd.initFriendship(ucacMain, id1, id2, {from: p1}).should.be.rejectedWith(h.EVMThrow);
        });
    });

    describe("Value setting and getting", () => {

        it("Individual setters and getters function correctly", async function() {

            // Add id and get length of friendIdList
            await this.fd.pushFriendId(ucacMain, id1, id2, {from: parent}).should.be.fulfilled;
            (await this.fd.numFriends(ucacMain, id1)).valueOf().should.equal("1");
            (await this.fd.numFriends(ucacMain, id2)).valueOf().should.equal("0");
            await this.fd.pushFriendId(ucacMain, id2, id1, {from: parent}).should.be.fulfilled;
            (await this.fd.numFriends(ucacMain, id1)).valueOf().should.equal("1");
            (await this.fd.numFriends(ucacMain, id2)).valueOf().should.equal("1");
            await this.fd.pushFriendId(ucacMain, id1, id3, {from: parent}).should.be.fulfilled;
            (await this.fd.numFriends(ucacMain, id1)).valueOf().should.equal("2");
            (await this.fd.numFriends(ucacMain, id2)).valueOf().should.equal("1");
            (await this.fd.numFriends(ucacMain, id3)).valueOf().should.equal("0");

            // Set and get id by index of friendIdList, throw on index calls beyond array length
            h.b2s((await this.fd.friendIdByIndex(ucacMain, id2, 0)).valueOf()).should.equal(id1);
            await this.fd.setFriendIdByIndex(ucacMain, id2, 1, id3, {from: parent}).should.be.rejectedWith(h.EVMThrow);
            await this.fd.friendIdByIndex(ucacMain, id2, 1).should.be.rejectedWith(h.EVMThrow);
            await this.fd.setFriendIdByIndex(ucacMain, id2, 0, id3, {from: parent}).should.be.fulfilled;
            h.b2s((await this.fd.friendIdByIndex(ucacMain, id2, 0)).valueOf()).should.equal(id3);

            // Set and get initialized of friendships, also test proper functioning of friendIndices
            await this.fd.fSetInitialized(ucacMain, id1, id2, true, {from: parent}).should.be.fulfilled;
            (await this.fd.fInitialized(ucacMain, id1, id2)).valueOf().should.equal(true);
            (await this.fd.fInitialized(ucacMain, id2, id1)).valueOf().should.equal(true);
            await this.fd.fSetInitialized(ucacMain, id2, id1, true, {from: parent}).should.be.fulfilled;
            await this.fd.fSetInitialized(ucacMain, id2, id1, false, {from: parent}).should.be.fulfilled;
            (await this.fd.fInitialized(ucacMain, id1, id2)).valueOf().should.equal(false);
            (await this.fd.fInitialized(ucacMain, id2, id1)).valueOf().should.equal(false);
            await this.fd.fSetInitialized(ucacMain, id1, id2, true, {from: parent}).should.be.fulfilled;
            (await this.fd.fInitialized(ucacMain, id1, id2)).valueOf().should.equal(true);
            (await this.fd.fInitialized(ucacMain, id2, id1)).valueOf().should.equal(true);

            // Set and get f1Id and f2Id of friendships
            await this.fd.fSetf1Id(ucacMain, id1, id2, id1, {from: parent}).should.be.fulfilled;
            h.b2s((await this.fd.ff1Id(ucacMain, id1, id2)).valueOf()).should.equal(id1);
            await this.fd.fSetf1Id(ucacMain, id1, id2, id2, {from: parent}).should.be.fulfilled;
            h.b2s((await this.fd.ff1Id(ucacMain, id1, id2)).valueOf()).should.equal(id2);
            await this.fd.fSetf2Id(ucacMain, id1, id2, id2, {from: parent}).should.be.fulfilled;
            h.b2s((await this.fd.ff2Id(ucacMain, id1, id2)).valueOf()).should.equal(id2);
            await this.fd.fSetf2Id(ucacMain, id1, id2, id1, {from: parent}).should.be.fulfilled;
            h.b2s((await this.fd.ff2Id(ucacMain, id1, id2)).valueOf()).should.equal(id1);

            // Set and get isPending, isMutual, f1Confirmed, and f2Confirmed
            await this.fd.fSetIsPending(ucacMain, id1, id2, true, {from: parent}).should.be.fulfilled;
            (await this.fd.fIsPending(ucacMain, id1, id2)).valueOf().should.equal(true);
            (await this.fd.fIsPending(ucacMain, id2, id1)).valueOf().should.equal(true);
            await this.fd.fSetIsPending(ucacMain, id1, id2, false, {from: parent}).should.be.fulfilled;
            (await this.fd.fIsPending(ucacMain, id1, id2)).valueOf().should.equal(false);
            (await this.fd.fIsPending(ucacMain, id2, id1)).valueOf().should.equal(false);

            await this.fd.fSetIsMutual(ucacMain, id1, id2, true, {from: parent}).should.be.fulfilled;
            (await this.fd.fIsMutual(ucacMain, id1, id2)).valueOf().should.equal(true);
            (await this.fd.fIsMutual(ucacMain, id2, id1)).valueOf().should.equal(true);
            await this.fd.fSetIsMutual(ucacMain, id1, id2, false, {from: parent}).should.be.fulfilled;
            (await this.fd.fIsMutual(ucacMain, id1, id2)).valueOf().should.equal(false);
            (await this.fd.fIsMutual(ucacMain, id2, id1)).valueOf().should.equal(false);

            await this.fd.fSetf1Confirmed(ucacMain, id1, id2, true, {from: parent}).should.be.fulfilled;
            (await this.fd.ff1Confirmed(ucacMain, id1, id2)).valueOf().should.equal(true);
            (await this.fd.ff1Confirmed(ucacMain, id2, id1)).valueOf().should.equal(true);
            await this.fd.fSetf1Confirmed(ucacMain, id1, id2, false, {from: parent}).should.be.fulfilled;
            (await this.fd.ff1Confirmed(ucacMain, id1, id2)).valueOf().should.equal(false);
            (await this.fd.ff1Confirmed(ucacMain, id2, id1)).valueOf().should.equal(false);

            await this.fd.fSetf2Confirmed(ucacMain, id1, id2, true, {from: parent}).should.be.fulfilled;
            (await this.fd.ff2Confirmed(ucacMain, id1, id2)).valueOf().should.equal(true);
            (await this.fd.ff2Confirmed(ucacMain, id2, id1)).valueOf().should.equal(true);
            await this.fd.fSetf2Confirmed(ucacMain, id1, id2, false, {from: parent}).should.be.fulfilled;
            (await this.fd.ff2Confirmed(ucacMain, id1, id2)).valueOf().should.equal(false);
            (await this.fd.ff2Confirmed(ucacMain, id2, id1)).valueOf().should.equal(false);
        });

        it("Batch function setting correctly", async function() {
            await this.fd.initFriendship(ucacMain, id1, id2, {from: parent}).should.be.fulfilled;

            // initialized correctly
            (await this.fd.fInitialized(ucacMain, id1, id2)).valueOf().should.equal(true);
            (await this.fd.fInitialized(ucacMain, id2, id1)).valueOf().should.equal(true);

            // f1Id and f2Id correct
            h.b2s((await this.fd.ff1Id(ucacMain, id1, id2)).valueOf()).should.equal(id1);
            h.b2s((await this.fd.ff1Id(ucacMain, id2, id1)).valueOf()).should.equal(id1);
            h.b2s((await this.fd.ff2Id(ucacMain, id1, id2)).valueOf()).should.equal(id2);
            h.b2s((await this.fd.ff2Id(ucacMain, id2, id1)).valueOf()).should.equal(id2);

            // isPending and isMutual correct
            (await this.fd.fIsPending(ucacMain, id1, id2)).valueOf().should.equal(true);
            (await this.fd.fIsPending(ucacMain, id2, id1)).valueOf().should.equal(true);
            (await this.fd.fIsMutual(ucacMain, id1, id2)).valueOf().should.equal(false);
            (await this.fd.fIsMutual(ucacMain, id2, id1)).valueOf().should.equal(false);

            // f1Confirmed and f2Confirmed correct
            (await this.fd.ff1Confirmed(ucacMain, id1, id2)).valueOf().should.equal(true);
            (await this.fd.ff1Confirmed(ucacMain, id2, id1)).valueOf().should.equal(true);
            (await this.fd.ff2Confirmed(ucacMain, id1, id2)).valueOf().should.equal(false);
            (await this.fd.ff2Confirmed(ucacMain, id2, id1)).valueOf().should.equal(false);

            // Friend list assignment correct
            (await this.fd.numFriends(ucacMain, id1)).valueOf().should.equal("1");
            (await this.fd.numFriends(ucacMain, id2)).valueOf().should.equal("1");

            // setting again with same id order does not change storage
            await this.fd.initFriendship(ucacMain, id1, id2, {from: parent}).should.be.fulfilled;
            (await this.fd.fInitialized(ucacMain, id1, id2)).valueOf().should.equal(true);
            (await this.fd.fInitialized(ucacMain, id2, id1)).valueOf().should.equal(true);
            h.b2s((await this.fd.ff1Id(ucacMain, id1, id2)).valueOf()).should.equal(id1);
            h.b2s((await this.fd.ff1Id(ucacMain, id2, id1)).valueOf()).should.equal(id1);
            h.b2s((await this.fd.ff2Id(ucacMain, id1, id2)).valueOf()).should.equal(id2);
            h.b2s((await this.fd.ff2Id(ucacMain, id2, id1)).valueOf()).should.equal(id2);
            (await this.fd.fIsPending(ucacMain, id1, id2)).valueOf().should.equal(true);
            (await this.fd.fIsPending(ucacMain, id2, id1)).valueOf().should.equal(true);
            (await this.fd.fIsMutual(ucacMain, id1, id2)).valueOf().should.equal(false);
            (await this.fd.fIsMutual(ucacMain, id2, id1)).valueOf().should.equal(false);
            (await this.fd.ff1Confirmed(ucacMain, id1, id2)).valueOf().should.equal(true);
            (await this.fd.ff1Confirmed(ucacMain, id2, id1)).valueOf().should.equal(true);
            (await this.fd.ff2Confirmed(ucacMain, id1, id2)).valueOf().should.equal(false);
            (await this.fd.ff2Confirmed(ucacMain, id2, id1)).valueOf().should.equal(false);
            (await this.fd.numFriends(ucacMain, id1)).valueOf().should.equal("2");
            (await this.fd.numFriends(ucacMain, id2)).valueOf().should.equal("2");

            // setting again with opposite id order does not change storage
            await this.fd.initFriendship(ucacMain, id2, id1, {from: parent}).should.be.fulfilled;
            (await this.fd.fInitialized(ucacMain, id1, id2)).valueOf().should.equal(true);
            (await this.fd.fInitialized(ucacMain, id2, id1)).valueOf().should.equal(true);
            h.b2s((await this.fd.ff1Id(ucacMain, id1, id2)).valueOf()).should.equal(id2);
            h.b2s((await this.fd.ff1Id(ucacMain, id2, id1)).valueOf()).should.equal(id2);
            h.b2s((await this.fd.ff2Id(ucacMain, id1, id2)).valueOf()).should.equal(id1);
            h.b2s((await this.fd.ff2Id(ucacMain, id2, id1)).valueOf()).should.equal(id1);
            (await this.fd.fIsPending(ucacMain, id1, id2)).valueOf().should.equal(true);
            (await this.fd.fIsPending(ucacMain, id2, id1)).valueOf().should.equal(true);
            (await this.fd.fIsMutual(ucacMain, id1, id2)).valueOf().should.equal(false);
            (await this.fd.fIsMutual(ucacMain, id2, id1)).valueOf().should.equal(false);
            (await this.fd.ff1Confirmed(ucacMain, id1, id2)).valueOf().should.equal(true);
            (await this.fd.ff1Confirmed(ucacMain, id2, id1)).valueOf().should.equal(true);
            (await this.fd.ff2Confirmed(ucacMain, id1, id2)).valueOf().should.equal(false);
            (await this.fd.ff2Confirmed(ucacMain, id2, id1)).valueOf().should.equal(false);
            (await this.fd.numFriends(ucacMain, id1)).valueOf().should.equal("3");
            (await this.fd.numFriends(ucacMain, id2)).valueOf().should.equal("3");

        });
    });

});
