var h = require("./helpers/helpers");

const should = require('chai')
          .use(require('chai-as-promised'))
          .use(require('chai-bignumber')(h.BigNumber))
          .should();

const StakeData = artifacts.require('./StakeData.sol');
const Stake = artifacts.require('./Stake.sol');
const CPToken = artifacts.require('tce-contracts/contracts/CPToken.sol');

contract('StakeData', function([admin1, admin2, parent, flux, p1, p2]) {

    before(async function() {
    });

    beforeEach(async function() {
        this.cpToken = await CPToken.new({from: admin1});
        this.stakeData = await StakeData.new(this.cpToken.address, {from: admin1});
        this.stake = await Stake.new(this.stakeData.address, {from: admin1});
        await this.cpToken.mint(p1, h.toWei(20000));
        await this.cpToken.finishMinting();
        await this.cpToken.endSale();
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

        it("Stake is able to call ucacTx  as parent", async function() {
            await this.stake.changeParent(flux, {from: admin1}).should.be.fulfilled;
            await this.stakeData.changeParent(this.stake.address, {from: admin1}).should.be.fulfilled;
            await this.cpToken.approve(this.stakeData.address, h.toWei(20000), {from: p1}).should.be.fulfilled;
            await this.stake.createAndStakeUcac(p1, p2, web3.fromAscii("hi"), 1001, {from: p1}).should.be.fulfilled;
            await this.stake.ucacTx(web3.fromAscii("hi"), {from: flux}).should.be.fulfilled;
            await this.stake.ucacTx(web3.fromAscii("hi"), {from: flux}).should.be.fulfilled;
        });
    });
});
