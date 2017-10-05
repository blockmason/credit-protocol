var h = require("./helpers/helpers");

const should = require('chai')
          .use(require('chai-as-promised'))
          .use(require('chai-bignumber')(h.BigNumber))
          .should();

const StakeData = artifacts.require('./StakeData.sol');
const CPToken = artifacts.require('./CPToken.sol');

contract('StakeData', function([admin1, admin2, parent, p1, p2]) {
    const id1 = "id1";
    const id2 = "id2";
    const ucacOne = "ucacOne";
    const one = web3.toBigNumber(1);
    const smallNumber = web3.toBigNumber(2);
    const bigNumber = web3.toBigNumber(9982372);

    before(async function() {
        // Advance to the next block to correctly read time in the solidity
        // "now" function interpreted by testrpc
    });

    beforeEach(async function() {
        this.stakeData = await StakeData.new({from: admin1});
        this.cpToken = await CPToken.new({from: admin1});
        this.cpTokenPrime = await CPToken.new({from: admin1});
        await this.stakeData.setAdmin2(admin2, {from: admin1});
        await this.stakeData.changeParent(parent, {from: admin1});
    });

    describe("UCAC info and ownership", () => {

        it("allows the token to be set and reset", async function() {
            await this.stakeData.setToken(this.cpToken.address, {from: admin1}).should.be.fulfilled;
            await this.stakeData.setToken(this.cpTokenPrime.address, {from: admin1}).should.be.fulfilled;
        });

    });

    describe("Stake tokens", () => {

    });

});
