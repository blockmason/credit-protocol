var h = require("./helpers/helpers");

const should = require('chai')
          .use(require('chai-as-promised'))
          .use(require('chai-bignumber')(h.BigNumber))
          .should();

const StakeData = artifacts.require('./StakeData.sol');
const Stake = artifacts.require('./Stake.sol');

contract('StakeData', function([admin1, admin2, parent, flux, p1, p2]) {

    before(async function() {
    });

    beforeEach(async function() {
        this.stakeData = await StakeData.new({from: admin1});
        this.stake = await Stake.new(this.stakeData.address, {from: admin1});
    });

    describe("UCAC parenthood", () => {

        it("onlyAdmin can change parents", async function() {
            await this.stake.changeParent(flux, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.stakeData.changeParent(this.stake.address, {from: p2}).should.be.rejectedWith(h.EVMThrow);
            await this.stake.changeParent(flux, {from: admin1}).should.be.fulfilled;
            await this.stakeData.changeParent(this.stake.address, {from: admin1}).should.be.fulfilled;
            await this.stake.changeParent(flux, {from: p2}).should.be.rejectedWith(h.EVMThrow);
            await this.stake.setAdmin2(admin2, {from: admin1}).should.be.fulfilled;
            await this.stake.changeParent(flux, {from: admin1}).should.be.fulfilled;
            await this.stake.changeParent(flux, {from: admin2}).should.be.fulfilled;
            await this.stakeData.changeParent(this.stake.address, {from: admin1}).should.be.fulfilled;
        });

        it("Stake is able to call getTotalStakedTokens as parent", async function() {
            await this.stake.changeParent(flux, {from: admin1}).should.be.fulfilled;
            await this.stakeData.changeParent(this.stake.address, {from: admin1}).should.be.fulfilled;
            const a = await this.stakeData.getTotalStakedTokens(web3.fromAscii("hi")).should.be.fulfilled;
            console.log(a);
            a.should.be.bignumber.equal(web3.toBigNumber(0));
            await this.stake.ucacTx(web3.fromAscii("hi"), {from: flux}).should.be.fulfilled;
        });


    });

});
