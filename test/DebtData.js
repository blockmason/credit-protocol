var h = require("./helpers/helpers");

const should = require('chai')
          .use(require('chai-as-promised'))
          .use(require('chai-bignumber')(h.BigNumber))
          .should();

const DebtData = artifacts.require('./DebtData.sol');

contract('DebtData', function([admin1, admin2, parent, p1, p2]) {
    const id1 = "id1";
    const id2 = "id2";
    const id3 = "id3";
    const ucacMain = "ucacMain";
    const smallNumber = 1;
    const bigNumber = 9982372;
    const currencyCode = "USD";
    const desc = "description";

    before(async function() {
        // Advance to the next block to correctly read time in the solidity
        // "now" function interpreted by testrpc
    });

    beforeEach(async function() {
        this.dd = await DebtData.new({from: admin1});
        await this.dd.setAdmin2(admin2, {from: admin1});
        await this.dd.changeParent(parent, {from: admin1});

        //initialize all fields for 2 way relationship to non-defaults
        await this.dd.incrementDebtId({from: parent});
        await this.dd.pushBlankDebt(ucacMain, id2, id1, {from: parent});
        await this.dd.dSetUcac(ucacMain, id1, id2, 0, {from: parent});
        await this.dd.dSetId(ucacMain, id1, id2, 0, smallNumber, {from: parent});
        await this.dd.dSetTimestamp(ucacMain, id1, id2, 0, bigNumber, {from: parent});
        await this.dd.dSetAmount(ucacMain, id1, id2, 0, smallNumber, {from: parent});
        await this.dd.dSetCurrencyCode(ucacMain, id1, id2, 0, currencyCode, {from: parent});
        await this.dd.dSetDebtorId(ucacMain, id1, id2, 0, id1, {from: parent});
        await this.dd.dSetDebtorId(ucacMain, id1, id2, 0, id2, {from: parent});
        await this.dd.dSetIsPending(ucacMain, id1, id2, 0, true, {from: parent});
        await this.dd.dSetIsRejected(ucacMain, id1, id2, 0, true, {from: parent});
        await this.dd.dSetDebtorConfirmed(ucacMain, id1, id2, 0, true, {from: parent});
        await this.dd.dSetCreditorConfirmed(ucacMain, id1, id2, 0, true, {from: parent});
        await this.dd.dSetDesc(ucacMain, id1, id2, 0, desc, {from: parent});
    });

    describe("Parent setting", () => {
        it("Non-admin can't change parent", async function() {
            await this.dd.changeParent(p1, {from: p2}).should.be.rejectedWith(h.EVMThrow);
        });
        it("Admins can change parent", async function() {
            await this.dd.changeParent(p1, {from: admin1}).should.be.fulfilled;
            await this.dd.changeParent(p1, {from: admin2}).should.be.fulfilled;
        });

    });
    /*

    describe("Value setting, getting, indices, and retrieval work", () => {
        it("has correct values for both directions of relationship", async function() {
            (await this.dd.numFriends(ucacMain, id1)).valueOf().should.equal("2");
            (await this.dd.numFriends(ucacMain, id2)).valueOf().should.equal("1");
            (await this.dd.numFriends(ucacMain, id3)).valueOf().should.equal("1");
            h.b2s((await this.dd.friendIdByIndex(ucacMain, id1, 0)).valueOf()).should.equal(id2);
            h.b2s((await this.dd.friendIdByIndex(ucacMain, id1, 1)).valueOf()).should.equal(id3);
            (await this.dd.fInitialized(ucacMain, id1, id2)).valueOf().should.equal(true);
            (await this.dd.fInitialized(ucacMain, id2, id1)).valueOf().should.equal(true);
            h.b2s((await this.dd.ff1Id(ucacMain, id1, id2)).valueOf()).should.equal(id1);
            h.b2s((await this.dd.ff1Id(ucacMain, id2, id1)).valueOf()).should.equal(id1);
            h.b2s((await this.dd.ff2Id(ucacMain, id1, id2)).valueOf()).should.equal(id2);
            h.b2s((await this.dd.ff2Id(ucacMain, id2, id1)).valueOf()).should.equal(id2);
            (await this.dd.fIsPending(ucacMain, id1, id2)).valueOf().should.equal(true);
            (await this.dd.fIsPending(ucacMain, id2, id1)).valueOf().should.equal(true);
            (await this.dd.fIsMutual(ucacMain, id1, id2)).valueOf().should.equal(true);
            (await this.dd.fIsMutual(ucacMain, id2, id1)).valueOf().should.equal(true);
            (await this.dd.ff1Confirmed(ucacMain, id1, id2)).valueOf().should.equal(true);
            (await this.dd.ff1Confirmed(ucacMain, id2, id1)).valueOf().should.equal(true);
            (await this.dd.ff2Confirmed(ucacMain, id1, id2)).valueOf().should.equal(true);
            (await this.dd.ff2Confirmed(ucacMain, id2, id1)).valueOf().should.equal(true);
        });

        it("Only parent contract can call setters", async function() {
            await this.dd.pushFriendId(ucacMain, id1, id2, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.dd.setFriendIdByIndex(ucacMain, id1, 0, id2, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.dd.fSetInitialized(ucacMain, id1, id2, true, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.dd.fSetf1Id(ucacMain, id1, id2, id1, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.dd.fSetf2Id(ucacMain, id1, id2, id2, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.dd.fSetIsPending(ucacMain, id1, id2, true, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.dd.fSetIsMutual(ucacMain, id1, id2, true, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.dd.fSetf1Confirmed(ucacMain, id1, id2, true, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.dd.fSetf2Confirmed(ucacMain, id1, id2, true, {from: p1}).should.be.rejectedWith(h.EVMThrow);
        });
    });
*/
});
