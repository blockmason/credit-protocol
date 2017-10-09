var h = require("./helpers/helpers");

const should = require('chai')
          .use(require('chai-as-promised'))
          .use(require('chai-bignumber')(h.BigNumber))
          .should();

const Stake = artifacts.require('./Stake.sol');
const StakeData = artifacts.require('./StakeData.sol');
const CPToken = artifacts.require('tce-contracts/contracts/CPToken.sol');

contract('Stake', function([admin1, admin2, parent, flux, p1, p2]) {
    const tooshort_ucacId = web3.fromAscii("short");
    const minlen_ucacId = web3.fromAscii("longenou");
    const maxlen_ucacId = web3.fromAscii("maxlengtmaxlengtmaxlengtmaxlengt");
    const toolong_ucacId = web3.fromAscii("toolongtoolongtoolongtoolongtoolong");
    const good_ucacId1 = web3.fromAscii("goodgoodgood1");
    const good_ucacId2 = web3.fromAscii("goodgoodgood2");
    const empty = web3.fromAscii(""); // not 100% sure about this
    const onebyte = web3.fromAscii("1");
    const tokensToOwnUcac = h.toWei(1000)
    const zero = new h.BigNumber(0);
    const one = new h.BigNumber(1);
    const two = new h.BigNumber(2);
    const three = new h.BigNumber(3);
    const four = new h.BigNumber(4);

    before(async function() {
    });

    beforeEach(async function() {
        this.cpToken = await CPToken.new({from: admin1});
        this.stakeData = await StakeData.new(this.cpToken.address, {from: admin1});
        this.stake = await Stake.new(this.stakeData.address, flux, {from: admin1});
        await this.stake.setAdmin2(admin2, {from: admin1});
        await this.stake.changeParent(parent, {from: admin1});
    });

    describe("Visibility restrictions", () => {
        it("onlyAdmin correct", async function() {
            await this.stake.setFlux(flux, {from: p2}).should.be.rejectedWith(h.EVMThrow);
            await this.stake.setFlux(flux, {from: admin1}).should.be.fulfilled;
            await this.stake.setFlux(flux, {from: admin2}).should.be.fulfilled;
        });
        
        it("onlyFlux correct", async function() {
            await this.stake.ucacTx(good_ucacId1, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.stake.ucacTx(good_ucacId1, {from: flux}).should.be.fulfilled;
        });
    });

    describe("Ucac status control", () => {
        
        beforeEach(async function() {
            // mint some tokens to p1, p2
            await this.cpToken.mint(p1, h.toWei(20000));
            await this.cpToken.mint(p2, h.toWei(0));
            await this.cpToken.finishMinting();
            await this.cpToken.endSale();
            await this.stake.createAndStakeUcac(p2, this.cpToken.address, good_ucacId1, tokensToOwnUcac, {from: p1});
        });
        
        it("ucacTx correct", async function() {
            // ucac not initialized
            await this.stake.ucacTx(good_ucacId2, {from: flux}).should.be.rejectedWith(h.EVMThrow);
            // first tx, txsPastHour = 1
            (await this.dd.ucacTxs[good_ucacId1].txsPastHour.call()).should.be.bignumber.equal(zero); // Unsure about this call
            await this.stake.ucacTx(good_ucacId1, {from: flux}).should.be.fulfilled;
            (await this.dd.ucacTxs[good_ucacId1].txsPastHour.call()).should.be.bignumber.equal(one);
            // second tx, txsPastHour = 2
            await this.stake.ucacTx(good_ucacId1, {from: flux}).should.be.fulfilled;
            (await this.dd.ucacTxs[good_ucacId1].txsPastHour.call()).should.be.bignumber.equal(two);
            // third tx, txsPastHour = 3
            await this.stake.ucacTx(good_ucacId1, {from: flux}).should.be.fulfilled;
            (await this.dd.ucacTxs[good_ucacId1].txsPastHour.call()).should.be.bignumber.equal(three);
            
            // time jump less than 1 hour
            h.increaseTime(500); // Unsure about this call
            (await this.dd.ucacTxs[good_ucacId1].txsPastHour.call()).should.be.bignumber.equal(three);
            // fourth tx, txsPastHour = 4
            await this.stake.ucacTx(good_ucacId1, {from: flux}).should.be.fulfilled;
            (await this.dd.ucacTxs[good_ucacId1].txsPastHour.call()).should.be.bignumber.equal(four);
            
            // time jump more than 1 hour
            h.increaseTime(10000);
            (await this.dd.ucacTxs[good_ucacId1].txsPastHour.call()).should.be.bignumber.equal(zero);
            // fifth tx, txsPastHour = 1
            await this.stake.ucacTx(good_ucacId1, {from: flux}).should.be.fulfilled;
            (await this.dd.ucacTxs[good_ucacId1].txsPastHour.call()).should.be.bignumber.equal(one);
            // seventh tx, txsPastHour = 2
            await this.stake.ucacTx(good_ucacId1, {from: flux}).should.be.fulfilled;
            (await this.dd.ucacTxs[good_ucacId1].txsPastHour.call()).should.be.bignumber.equal(two);
            // eighth tx, txsPastHour = 3
            await this.stake.ucacTx(good_ucacId1, {from: flux}).should.be.fulfilled;
            (await this.dd.ucacTxs[good_ucacId1].txsPastHour.call()).should.be.bignumber.equal(three);
        });
        
        it("ucacStatus correct", async function() {
            
        });
    });
    
    describe("Other functions", () => {
        
        beforeEach(async function() {
            // mint some tokens to p1, p2
            await this.cpToken.mint(p1, h.toWei(20000));
            await this.cpToken.mint(p2, h.toWei(0));
            await this.cpToken.finishMinting();
            await this.cpToken.endSale();
            await this.stake.createAndStakeUcac(p2, this.cpToken.address, good_ucacId1, tokensToOwnUcac, {from: p1});
        });
        
        it("stakeTokens correct", async function() {
            // ucac initialized
            await this.stake.stakeTokens(good_ucacId1, h.toWei(500), {from: p1}).should.be.fulfilled;
            // ucac not initialized
            await this.stake.stakeTokens(good_ucacId2, h.toWei(500), {from: p1}).should.be.rejectedWith(h.EVMThrow);
        });
        
        it("ucacInitialized correct", async function() {
            // ucac initialized
            (await this.stake.ucacInitialized(good_ucacId1, {from: p1})).valueOf().should.equal(true);
            // ucac not initialized
            (await this.stake.ucacInitialized(good_ucacId2, {from: p1})).valueOf().should.equal(false);
        });
        
        it("bytes32Len correct", async function() {
            // empty string
            (await this.stake.bytes32Len(empty)).valueOf().should.equal("0"); // Unsure about this call
            // 1 byte string
            (await this.stake.bytes32Len(onebyte)).valueOf().should.equal("1");
            // 13 byte string
            (await this.stake.bytes32Len(good_ucacId1)).valueOf().should.equal("13");
            // 32 byte string
            (await this.stake.bytes32Len(maxlen_ucacId)).valueOf().should.equal("32");
            // 35 byte string
            await this.stake.bytes32Len(toolong_ucacId).should.be.rejectedWith(h.EVMThrow);
        });
        
    });
    
    describe("Ownership functions", () => {

        beforeEach(async function() {
            // mint some tokens
            await this.cpToken.mint(admin1, h.toWei(20000));
            await this.cpToken.mint(admin2, h.toWei(5000));
            await this.cpToken.mint(p1, h.toWei(20000));
            await this.cpToken.mint(p2, h.toWei(0));
            await this.cpToken.finishMinting();
            await this.cpToken.endSale();
        });
        
        it("createAndStakeUcac correct", async function() {
            // correct function
            await this.stake.createAndStakeUcac(p2, this.cpToken.address, minlen_ucacId, tokensToOwnUcac, {from: p1}).should.be.fulfilled;
            await this.stake.createAndStakeUcac(p2, this.cpToken.address, maxlen_ucacId, tokensToOwnUcac, {from: p1}).should.be.fulfilled;
            // existing ucacId
            await this.stake.createAndStakeUcac(p2, this.cpToken.address, minlen_ucacId, tokensToOwnUcac, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            // ucacId too short
            await this.stake.createAndStakeUcac(p2, this.cpToken.address, tooshort_ucacId, tokensToOwnUcac, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            // ucacId too long
            await this.stake.createAndStakeUcac(p2, this.cpToken.address, toolong_ucacId, tokensToOwnUcac, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            // too few tokens sent
            await this.stake.createAndStakeUcac(p2, this.cpToken.address, good_ucacId2, h.toWei(500), {from: p1}).should.be.rejectedWith(h.EVMThrow);
            // too few tokens owned
            await this.stake.createAndStakeUcac(p1, this.cpToken.address, good_ucacId2, tokensToOwnUcac, {from: p2}).should.be.rejectedWith(h.EVMThrow);
        });
        
        it("takeoverUcac correct", async function() {
            // takeover with new stake
            await this.stake.createAndStakeUcac(admin2, this.cpToken.address, good_ucacId1, tokensToOwnUcac, {from: admin1});
            await this.stakedata.unstakeTokens(good_ucacId1, h.toWei(500), {from: admin1});
            await this.stake.takeoverUcac(p2, this.cpToken.address, good_ucacId1, tokensToOwnUcac, {from: p1}).should.be.fulfilled;
            await this.stakedata.getOwner1(good_ucacId1).should.be.bignumber.equal(p1);
            await this.stakedata.getOwner2(good_ucacId1).should.be.bignumber.equal(p2);
            // takeover with existing stake
            await this.stake.createAndStakeUcac(admin2, this.cpToken.address, good_ucacId2, tokensToOwnUcac, {from: admin1});
            await this.stake.stakeTokens(good_ucacId2, tokensToOwnUcac, {from: p1});
            await this.stakedata.unstakeTokens(good_ucacId2, h.toWei(500), {from: admin1});
            await this.stake.takeoverUcac(p2, this.cpToken.address, good_ucacId2, h.toWei(0), {from: p1}).should.be.fulfilled;
            await this.stakedata.getOwner1(good_ucacId1).should.be.bignumber.equal(p1);
            await this.stakedata.getOwner2(good_ucacId1).should.be.bignumber.equal(p2);
        });
        
        it("takeoverUcac throws", async function() {
            // create ucac
            await this.stake.createAndStakeUcac(admin2, this.cpToken.address, good_ucacId1, tokensToOwnUcac, {from: admin1});
            // current owner1 stake big enough
            await this.stake.takeoverUcac(p2, this.cpToken.address, good_ucacId1, tokensToOwnUcac, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            // current owner2 stake big enough, need to confirm this is desired behaviour
            await this.stakedata.unstakeTokens(good_ucacId1, h.toWei(500), {from: admin1});
            await this.stake.stakeTokens(good_ucacId1, tokensToOwnUcac, {from: admin2});
            await this.stake.takeoverUcac(p2, this.cpToken.address, good_ucacId1, tokensToOwnUcac, {from: p1}).should.be.rejectedWith(h.EVMThrow); 
            // new owner not stake enough
            await this.stakedata.unstakeTokens(good_ucacId1, h.toWei(500), {from: admin2});
            await this.stake.takeoverUcac(p1, this.cpToken.address, good_ucacId1, h.toWei(0), {from: p2}).should.be.rejectedWith(h.EVMThrow);
            await this.stake.takeoverUcac(p1, this.cpToken.address, good_ucacId1, tokensToOwnUcac, {from: p2}).should.be.rejectedWith(h.EVMThrow);
            // ucac not initialized
            await this.stake.takeoverUcac(p2, this.cpToken.address, good_ucacId2, tokensToOwnUcac, {from: p1}).should.be.rejectedWith(h.EVMThrow);
        });
        
        it("transferUcacOwnership correct", async function() {
            // initialize and stake a ucac
            await this.stake.createAndStakeUcac(admin2, this.cpToken.address, good_ucacId1, tokensToOwnUcac, {from: admin1});
            await this.stake.stakeTokens(good_ucacId1, tokensToOwnUcac, {from: p1});
            // correct function
            await this.stake.transferUcacOwnership(good_ucacId1, p1, p2, {from: admin1}).should.be.fulfilled;
            await this.stakedata.getOwner1(good_ucacId1).should.be.bignumber.equal(p1);
            await this.stakedata.getOwner2(good_ucacId1).should.be.bignumber.equal(p2);
            // ucac not initialized
            await this.stake.transferUcacOwnership(good_ucacId2, admin1, p2, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            // msg.sender not owner
            await this.stake.transferUcacOwnership(good_ucacId1, admin1, p2, {from: admin1}).should.be.rejectedWith(h.EVMThrow);
            // newOwnerStake too small
            await this.stake.transferUcacOwnership(good_ucacId1, admin2, p2, {from: p1}).should.be.rejectedWith(h.EVMThrow);
        });
        
    });
    
});
