var h = require("./helpers/helpers");

const should = require('chai')
          .use(require('chai-as-promised'))
          .use(require('chai-bignumber')(h.BigNumber))
          .should();

const FoundationData = artifacts.require('./FoundationData.sol');
const Foundation = artifacts.require('./Foundation.sol');
const FriendData = artifacts.require('./FriendData.sol');
const FriendInterface = artifacts.require('./FriendInterface.sol');

contract('FriendInterface', function([admin1, admin2, parent, p1, p2, p3]) {
    const adminId = "adminId";
    const id1 = "timg";
    const id2 = "jaredb";
    const id3 = "lukez";
    const ucacMain = "ucacMain";

    before(async function() {
        this.foundationData = await FoundationData.new(adminId, {from: admin1});
        this.foundation = await Foundation.new(this.foundationData.address, adminId, 0, 0, {from: admin1});
        await this.foundationData.setFoundationContract(this.foundation.address, {from: admin1});
        await this.foundation.createId(id1, {from: p1});
        await this.foundation.createId(id2, {from: p2});
        await this.foundation.createId(id3, {from: p3});
    });

    beforeEach(async function() {
        this.friendData = await FriendData.new({from: admin1});
        await this.friendData.setAdmin2(admin2, {from: admin1});

        this.fi = await FriendInterface.new(this.friendData.address, this.foundation.address, {from: admin1});
        await this.friendData.changeParent(this.fi.address, {from: admin1});

        await this.fi.setAdmin2(admin2, {from: admin1});
        await this.fi.changeParent(parent, {from: admin1});
    });

    describe("Initial", () => {
        it("timtime", async function() {

        });
    });
});
