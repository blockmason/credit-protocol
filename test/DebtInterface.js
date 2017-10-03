var h = require("./helpers/helpers");

const should = require('chai')
          .use(require('chai-as-promised'))
          .use(require('chai-bignumber')(h.BigNumber))
          .should();

const FoundationData = artifacts.require('./FoundationData.sol');
const Foundation = artifacts.require('./Foundation.sol');
const DebtData = artifacts.require('./DebtData.sol');
const DebtInterface = artifacts.require('./DebtInterface.sol');

contract('DebtInterface', function([admin1, admin2, parent, p1, p2, p3]) {
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
        this.debtData = await DebtData.new({from: admin1});
        await this.debtData.setAdmin2(admin2, {from: admin1});

        this.di = await DebtInterface.new(this.debtData.address, this.foundation.address, {from: admin1});
        await this.debtData.changeParent(this.di.address, {from: admin1});

        await this.di.setAdmin2(admin2, {from: admin1});
        await this.di.changeParent(parent, {from: admin1});
    });

    describe("Initial", () => {
        it("timtime", async function() {

        });
    });
});
