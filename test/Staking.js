var h = require("./helpers/helpers");

const should = require('chai')
          .use(require('chai-as-promised'))
          .use(require('chai-bignumber')(h.BigNumber))
          .should();

const StakeData = artifacts.require('./StakeData.sol');
const Stake = artifacts.require('./Stake.sol');
const CPToken = artifacts.require('tce-contracts/contracts/CPToken.sol');

const ucacId1 = web3.fromAscii("hi");
const ucacId2 = web3.fromAscii("yo");
const tokensToOwnUcac = web3.toWei(1000);

contract('StakeData', function([admin1, admin2, parent, flux, p1, p2]) {

    before(async function() {
    });

    beforeEach(async function() {
        this.cpToken = await CPToken.new({from: admin1});
        this.stakeData = await StakeData.new(this.cpToken.address, {from: admin1});
        this.stake = await Stake.new(this.stakeData.address, {from: admin1});
        await this.cpToken.mint(p1, h.toWei(20000));
        await this.cpToken.mint(p2, h.toWei(20000));
        await this.cpToken.mint(admin1, h.toWei(20000));
        await this.cpToken.finishMinting();
        await this.cpToken.endSale();
        await this.stake.changeParent(flux, {from: admin1}).should.be.fulfilled;
        await this.stakeData.changeParent(this.stake.address, {from: admin1}).should.be.fulfilled;
    });

    describe("UCAC parenthood, basic ucac creation, staking and txing", () => {

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

        it("createAndStakeUcac requires minimum stake & ucacInitilized detects initialized and uninitialized ucacs", async function() {
            // not enough approved tokens to create UCAC
            await this.stake.createAndStakeUcac(p1, p2, ucacId1, h.toWei(1001), {from: p1}).should.be.rejectedWith(h.EVMThrow);
            assert(!(await this.stake.ucacInitialized(ucacId1)), "ucac is uninitialized");
            await this.cpToken.approve(this.stakeData.address, h.toWei(20000), {from: p1}).should.be.fulfilled;

            // not enough tokens staked to create UCAC
            await this.stake.createAndStakeUcac(p1, p2, ucacId1, h.toWei(101), {from: p1}).should.be.rejectedWith(h.EVMThrow);
            assert(!(await this.stake.ucacInitialized(ucacId1)), "ucac is uninitialized");
            // can initialize UCAC  with minimum staking amount
            await this.stake.createAndStakeUcac(p1, p2, ucacId1, h.toWei(1001), {from: p1}).should.be.fulfilled;
            assert(await this.stake.ucacInitialized(ucacId1), "ucac is initialized");
        });

        it("stakeTokens stakes appropriate number of tokens for initialized ucacs", async function() {
            const creationStake = web3.toBigNumber(web3.toWei(3500));
            const postCreationStake = web3.toBigNumber(web3.toWei(100));
            await this.cpToken.approve(this.stakeData.address, h.toWei(20000), {from: p1}).should.be.fulfilled;
            // stakeTokens call rejected prior to initialization
            await this.stake.stakeTokens(ucacId2, h.toWei(100), {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.stake.createAndStakeUcac(p1, p2, ucacId2, creationStake, {from: p1}).should.be.fulfilled;
            // stakeTokens call successful post-initialization
            await this.stake.stakeTokens(ucacId2, postCreationStake, {from: p1}).should.be.fulfilled;
            const a = await this.stake.ucacStatus(ucacId2).should.be.fulfilled;
            a[0].should.be.bignumber.equal(creationStake.add(postCreationStake));
        });

        it("Stake.sol is able to call ucacTx as parent of StakeData.sol", async function() {
            await this.cpToken.approve(this.stakeData.address, h.toWei(20000), {from: p1}).should.be.fulfilled;
            await this.stake.createAndStakeUcac(p1, p2, ucacId1, h.toWei(1001), {from: p1}).should.be.fulfilled;
            await this.stake.ucacTx(ucacId1, {from: flux}).should.be.fulfilled;
            await this.stake.ucacTx(ucacId1, {from: flux}).should.be.fulfilled;
            await this.stake.ucacTx(ucacId1, {from: flux}).should.be.fulfilled;
        });

        it("ucacTx decay mechanism works as expected, blocks txs beyond limit", async function() {

        });

    });

    describe("UCAC ownership", () => {

        it("can take over ucac", async function() {
            await this.cpToken.approve(this.stakeData.address, h.toWei(20000), {from: admin1}).should.be.fulfilled;
            await this.cpToken.approve(this.stakeData.address, h.toWei(20000), {from: p1}).should.be.fulfilled;
            await this.cpToken.approve(this.stakeData.address, h.toWei(20000), {from: p2}).should.be.fulfilled;
            // takeover with new stake
            await this.stake.createAndStakeUcac(p1, p2, ucacId1, h.toWei(1001), {from: p1}).should.be.fulfilled;
            await this.stakeData.unstakeTokens(ucacId1, h.toWei(500), {from: p1}).should.be.fulfilled;
            await this.stake.takeOverUcac(admin1, this.cpToken.address, ucacId1, tokensToOwnUcac, {from: p2}).should.be.fulfilled;
            assert(p2 === await this.stakeData.getOwner1(ucacId1), "address string matches p2");
            assert(admin1 === await this.stakeData.getOwner2(ucacId1), "address string matches admin1");

            // takeover with existing stake
            await this.stake.createAndStakeUcac(admin2, this.cpToken.address, ucacId2, tokensToOwnUcac, {from: admin1});
            await this.stake.stakeTokens(ucacId2, tokensToOwnUcac, {from: p1});
            await this.stakeData.unstakeTokens(ucacId2, h.toWei(500), {from: admin1});
            await this.stake.takeOverUcac(p2, this.cpToken.address, ucacId2, 0, {from: p1}).should.be.fulfilled;
            assert(p1 === await this.stakeData.getOwner1(ucacId2), "address string matches p2");
            assert(p2 === await this.stakeData.getOwner2(ucacId2), "address string matches admin1");
        });

        it("can transfer ucac ownership", async function() {
            await this.cpToken.approve(this.stakeData.address, h.toWei(20000), {from: admin1}).should.be.fulfilled;
            await this.cpToken.approve(this.stakeData.address, h.toWei(20000), {from: admin2}).should.be.fulfilled;
            await this.cpToken.approve(this.stakeData.address, h.toWei(20000), {from: p1}).should.be.fulfilled;
            await this.cpToken.approve(this.stakeData.address, h.toWei(20000), {from: p2}).should.be.fulfilled;

            // initialize and stake a ucac
            await this.stake.createAndStakeUcac(admin2, this.cpToken.address, ucacId1, tokensToOwnUcac, {from: admin1});
            await this.stake.stakeTokens(ucacId1, tokensToOwnUcac, {from: p1});
            // correct function
            await this.stake.transferUcacOwnership(ucacId1, p1, p2, {from: admin1}).should.be.fulfilled;
            assert(p1 === await this.stakeData.getOwner1(ucacId1), "address string matches p2");
            assert(p2 === await this.stakeData.getOwner2(ucacId1), "address string matches admin1");
            // ucac not initialized
            await this.stake.transferUcacOwnership(ucacId2, admin1, p2, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            // msg.sender not owner
            await this.stake.transferUcacOwnership(ucacId1, admin1, p2, {from: admin1}).should.be.rejectedWith(h.EVMThrow);
            // newOwnerStake too small
            await this.stake.transferUcacOwnership(ucacId1, admin2, p2, {from: p1}).should.be.rejectedWith(h.EVMThrow);
        });

    });
});
