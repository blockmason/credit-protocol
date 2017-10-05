var h = require("./helpers/helpers");

const should = require('chai')
          .use(require('chai-as-promised'))
          .use(require('chai-bignumber')(h.BigNumber))
          .should();

const StakeData = artifacts.require('./StakeData.sol');

contract('StakeData', function([admin1, admin2, parent, p1, p2]) {
    const id1 = "id1";
    const id2 = "id2";
    const ucacOne = "ucacOne";
    const one = new h.BigNumber(1);
    const smallNumber = new h.BigNumber(2);
    const bigNumber = new h.BigNumber(9982372);

    before(async function() {
        // Advance to the next block to correctly read time in the solidity
        // "now" function interpreted by testrpc
    });

    beforeEach(async function() {
        this.sd = await StakeData.new({from: admin1});
        await this.sd.setAdmin2(admin2, {from: admin1});
        await this.dd.changeParent(parent, {from: admin1});
    });

    describe("UCAC info and ownership", () => {

    });

    describe("Stake tokens", () => {

    });

});
