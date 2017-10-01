var h = require("./helpers/helpers");

const should = require('chai')
          .use(require('chai-as-promised'))
          .use(require('chai-bignumber')(h.BigNumber))
          .should();

const FriendData = artifacts.require('./FriendData.sol');

contract('FriendData', function([admin1, admin2, parent, p1, p2]) {
    before(async function() {
        // Advance to the next block to correctly read time in the solidity
        // "now" function interpreted by testrpc
    });

    beforeEach(async function() {
        this.fd = await FriendData.new({from: admin1});
        await this.fd.changeParent(parent, {from: admin1});
    });

    describe("Adminable setting", () => {
        it("non-admin can't add 2nd admin", async function() {
            await this.fd.setAdmin2(admin2, {from: admin2}).should.be.rejectedWith(h.EVMThrow);
        });

        it("admin1 can add 2nd admin", async function() {
            await this.fd.setAdmin2(admin2, {from: admin1}).should.be.fulfilled;
        });

        it("Non-admin can't change 1st admin", async function() {
            await this.fd.setAdmin1(admin1, {from: p2}).should.be.rejectedWith(h.EVMThrow);
        });

        it("Non-admin can't change 2nd admin", async function() {
            await this.fd.setAdmin2(admin2, {from: p2}).should.be.rejectedWith(h.EVMThrow);
        });

        it("Admin1 can change 1st admin", async function() {
            await this.fd.setAdmin1(admin1, {from: admin1}).should.be.fulfilled;
        });

        it("Admin1 can change 2nd admin", async function() {
            await this.fd.setAdmin1(admin1, {from: admin1}).should.be.fulfilled;
        });

        it("Admin2 can change 1st admin", async function() {
            await this.fd.setAdmin2(admin2, {from: admin1}).should.be.fulfilled;
            await this.fd.setAdmin1(admin1, {from: admin2}).should.be.fulfilled;
        });

        it("Admin2 can change 2nd admin", async function() {
            await this.fd.setAdmin2(admin2, {from: admin1}).should.be.fulfilled;
            await this.fd.setAdmin1(admin1, {from: admin2}).should.be.fulfilled;
        });
    });

    describe("Adminable modifiers and Parentable setting", () => {
        it("admin can change parent", async function() {
            await this.fd.changeParent(p1, {from: admin1}).should.be.fulfilled;
        });

        it("non-admin can't change parent", async function() {
            await this.fd.changeParent(p1, {from: p2}).should.be.rejectedWith(h.EVMThrow);
        });

        it("admin can change parent", async function() {
            await this.fd.changeParent(p1, {from: admin1});
        });
    });

    describe("Parentable modifiers", () => {
        const id1 = "myId";
        const id2 = "friendId";
        const ucacId = "ucac1";
        it("non-parent can't call onlyParent-protected function", async function() {
            await this.fd.pushFriendId(ucacId, id1, id2, {from: admin1}).should.be.rejectedWith(h.EVMThrow);
        });

        it("Parent can call onlyParent-protected function", async function() {
            await this.fd.pushFriendId(ucacId, id1, id2, {from: parent}).should.be.fulfilled;
        });
    });
});
