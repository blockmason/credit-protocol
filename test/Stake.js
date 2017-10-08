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
    const one = web3.fromAscii("1");

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
        
        it("ucacTx correct", async function() {
            
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
            await this.stake.createAndStakeUcac(p2, this.cpToken.address, good_ucacId1, h.toWei(1000), {from: p1});
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
            (await this.stake.bytes32Len(empty)).valueOf().should.equal("0");
            // 1 byte string
            (await this.stake.bytes32Len(one)).valueOf().should.equal("1");
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
            // mint some tokens to p1, p2
            await this.cpToken.mint(p1, h.toWei(20000));
            await this.cpToken.mint(p2, h.toWei(0));
            await this.cpToken.finishMinting();
            await this.cpToken.endSale();
        });
        
        it("createAndStakeUcac correct", async function() {
            // correct function
            await this.stake.createAndStakeUcac(p2, this.cpToken.address, minlen_ucacId, h.toWei(1000), {from: p1}).should.be.fulfilled;
            await this.stake.createAndStakeUcac(p2, this.cpToken.address, maxlen_ucacId, h.toWei(1000), {from: p1}).should.be.fulfilled;
            // existing ucacId
            await this.stake.createAndStakeUcac(p2, this.cpToken.address, minlen_ucacId, h.toWei(1000), {from: p1}).should.be.rejectedWith(h.EVMThrow);
            // ucacId too short
            await this.stake.createAndStakeUcac(p2, this.cpToken.address, tooshort_ucacId, h.toWei(1000), {from: p1}).should.be.rejectedWith(h.EVMThrow);
            // ucacId too long
            await this.stake.createAndStakeUcac(p2, this.cpToken.address, toolong_ucacId, h.toWei(1000), {from: p1}).should.be.rejectedWith(h.EVMThrow);
            // too few tokens sent
            await this.stake.createAndStakeUcac(p2, this.cpToken.address, good_ucacId1, h.toWei(500), {from: p1}).should.be.rejectedWith(h.EVMThrow);
            // too few tokens owned
            await this.stake.createAndStakeUcac(p1, this.cpToken.address, good_ucacId1, h.toWei(1000), {from: p2}).should.be.rejectedWith(h.EVMThrow);
        });
        
        it("takeoverUcac correct", async function() {
            
        });
        
        it("transferUcacOwnership correct", async function() {
            
        });
        
    });
    
});
