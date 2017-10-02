var h = require("./helpers/helpers");

const should = require('chai')
          .use(require('chai-as-promised'))
          .use(require('chai-bignumber')(h.BigNumber))
          .should();

const DebtData = artifacts.require('./DebtData.sol');

contract('DebtData', function([admin1, admin2, parent, p1, p2]) {
    const id1 = "id1";
    const id2 = "id2";
    const ucacMain = "ucacMain";
    const one = new h.BigNumber(1);
    const smallNumber = new h.BigNumber(2);
    const bigNumber = new h.BigNumber(9982372);
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
        await this.dd.dSetId(ucacMain, id1, id2, 0, smallNumber, {from: parent});
        await this.dd.dSetTimestamp(ucacMain, id1, id2, 0, bigNumber, {from: parent});
        await this.dd.dSetAmount(ucacMain, id1, id2, 0, smallNumber, {from: parent});
        await this.dd.dSetCurrencyCode(ucacMain, id1, id2, 0, currencyCode, {from: parent});
        await this.dd.dSetDebtorId(ucacMain, id1, id2, 0, id1, {from: parent});
        await this.dd.dSetCreditorId(ucacMain, id1, id2, 0, id2, {from: parent});
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

    describe("Value setting, getting, indices, and retrieval work", () => {
        it("has correct values for both directions of relationship", async function() {
            (await this.dd.nextDebtId.call()).should.be.bignumber.equal(one);
            (await this.dd.numDebts(ucacMain, id1, id2)).should.be.bignumber.equal(one);
            (await this.dd.numDebts(ucacMain, id2, id1)).should.be.bignumber.equal(one);

            (await this.dd.dId(ucacMain, id1, id2, 0)).should.be.bignumber.equal(smallNumber);
            (await this.dd.dId(ucacMain, id2, id1, 0)).should.be.bignumber.equal(smallNumber);
            (await this.dd.dTimestamp(ucacMain, id1, id2, 0)).should.be.bignumber.equal(bigNumber);
            (await this.dd.dTimestamp(ucacMain, id2, id1, 0)).should.be.bignumber.equal(bigNumber);
            (await this.dd.dAmount(ucacMain, id1, id2, 0)).should.be.bignumber.equal(smallNumber);
            (await this.dd.dAmount(ucacMain, id2, id1, 0)).should.be.bignumber.equal(smallNumber);

            h.b2s((await this.dd.dCurrencyCode(ucacMain, id1, id2, 0)).valueOf()).should.equal(currencyCode);
            h.b2s((await this.dd.dCurrencyCode(ucacMain, id2, id1, 0)).valueOf()).should.equal(currencyCode);
            h.b2s((await this.dd.dDebtorId(ucacMain, id1, id2, 0)).valueOf()).should.equal(id1);
            h.b2s((await this.dd.dDebtorId(ucacMain, id2, id1, 0)).valueOf()).should.equal(id1);
            h.b2s((await this.dd.dCreditorId(ucacMain, id1, id2, 0)).valueOf()).should.equal(id2);
            h.b2s((await this.dd.dCreditorId(ucacMain, id2, id1, 0)).valueOf()).should.equal(id2);

            (await this.dd.dIsPending(ucacMain, id1, id2, 0)).valueOf().should.equal(true);
            (await this.dd.dIsPending(ucacMain, id2, id1, 0)).valueOf().should.equal(true);
            (await this.dd.dIsRejected(ucacMain, id1, id2, 0)).valueOf().should.equal(true);
            (await this.dd.dIsRejected(ucacMain, id2, id1, 0)).valueOf().should.equal(true);
            (await this.dd.dDebtorConfirmed(ucacMain, id1, id2, 0)).valueOf().should.equal(true);
            (await this.dd.dCreditorConfirmed(ucacMain, id2, id1, 0)).valueOf().should.equal(true);
            h.b2s((await this.dd.dDesc(ucacMain, id1, id2, 0)).valueOf()).should.equal(desc);
            h.b2s((await this.dd.dDesc(ucacMain, id2, id1, 0)).valueOf()).should.equal(desc);
        });

        it("Only parent contract can call setters", async function() {
            await this.dd.incrementDebtId({from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.dd.pushBlankDebt(ucacMain, id2, id1, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.dd.dSetId(ucacMain, id1, id2, 0, smallNumber, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.dd.dSetTimestamp(ucacMain, id1, id2, 0, bigNumber, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.dd.dSetAmount(ucacMain, id1, id2, 0, smallNumber, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.dd.dSetCurrencyCode(ucacMain, id1, id2, 0, currencyCode, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.dd.dSetDebtorId(ucacMain, id1, id2, 0, id1, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.dd.dSetDebtorId(ucacMain, id1, id2, 0, id2, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.dd.dSetIsPending(ucacMain, id1, id2, 0, true, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.dd.dSetIsRejected(ucacMain, id1, id2, 0, true, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.dd.dSetDebtorConfirmed(ucacMain, id1, id2, 0, true, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.dd.dSetCreditorConfirmed(ucacMain, id1, id2, 0, true, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.dd.dSetDesc(ucacMain, id1, id2, 0, desc, {from: p1}).should.be.rejectedWith(h.EVMThrow);
        });
    });
});
