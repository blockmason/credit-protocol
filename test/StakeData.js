var h = require("./helpers/helpers");

const should = require('chai')
          .use(require('chai-as-promised'))
          .use(require('chai-bignumber')(h.BigNumber))
          .should();

const StakeData = artifacts.require('./StakeData.sol');
const CPToken = artifacts.require('./CPToken.sol');

contract('StakeData', function([admin1, admin2, parent, p1, p2]) {
    const ucacId1 = web3.fromAscii("id1");
    const ucacId2 = web3.fromAscii("id2");
    const ucacOne = "ucacOne";
    const one = web3.toBigNumber(1);
    const smallNumber = web3.toBigNumber(2);
    const bigNumber = web3.toBigNumber(9982372);

    before(async function() {
    });

    beforeEach(async function() {
        this.stakeData = await StakeData.new({from: admin1});
        this.cpToken = await CPToken.new({from: admin1});
        this.cpTokenPrime = await CPToken.new({from: admin1});
        await this.stakeData.setAdmin2(admin2, {from: admin1});
        await this.stakeData.changeParent(parent, {from: admin1});
    });

    describe("UCAC info and ownership", () => {

        beforeEach(async function() {
            await this.stakeData.setToken(this.cpToken.address, {from: admin1}).should.be.fulfilled;
        });

        it("allows the token to be set and reset", async function() {
            // check initial token address
            const addr = await this.stakeData.currentToken();
            addr.should.be.bignumber.equal(this.cpToken.address);

            // check that token address can be changed with a second call to
            // `setToken`
            await this.stakeData.setToken(this.cpTokenPrime.address, {from: admin1}).should.be.fulfilled;
            const addrPrime = await this.stakeData.currentToken();
            addrPrime.should.be.bignumber.equal(this.cpTokenPrime.address);
        });

        it("allows Ucac info (ucacAddr, owner1, owner2) to be set and reset", async function() {
            // rejects attemps to set UcacAddr by non-parent
            await this.stakeData.setUcacAddr(this.cpToken.address, ucacId1, this.cpToken.address, {from: admin1}).should.be.rejectedWith(h.EVMThrow);

            // ## testing with ucacId1
            await this.stakeData.setUcacAddr(this.cpToken.address, ucacId1, this.cpToken.address, {from: parent}).should.be.fulfilled;
            await this.stakeData.setOwner1(this.cpToken.address, ucacId1, admin1, {from: parent}).should.be.fulfilled;
            await this.stakeData.setOwner2(this.cpToken.address, ucacId1, admin1, {from: parent}).should.be.fulfilled;
            const addr1 = await this.stakeData.getUcacAddr(this.cpToken.address, ucacId1).should.be.fulfilled;
            addr1.should.be.bignumber.equal(this.cpToken.address);
            const owner1 = await this.stakeData.getUcacAddr(this.cpToken.address, ucacId1).should.be.fulfilled;
            addr1.should.be.bignumber.equal(this.cpToken.address);
            const owner2 = await this.stakeData.getOwner1(this.cpToken.address, ucacId1).should.be.fulfilled;
            addr1.should.be.bignumber.equal(this.cpToken.address);

            // ### testing isOwner
            const isOwnerT1 = await this.stakeData.isOwner(this.cpToken.address, ucacId1, admin1).should.be.fulfilled;
            assert(isOwnerT1, "admit1 is an owner of ucacId2");
            const isOwnerT2 = await this.stakeData.isOwner(this.cpToken.address, ucacId1, admin2).should.be.fulfilled;
            assert(!isOwnerT2, "admin2 is not an owner of ucacId2");

            // ## testing with ucacId2
            await this.stakeData.setUcacAddr(this.cpToken.address, ucacId2, web3.toBigNumber(3), {from: parent}).should.be.fulfilled;
            await this.stakeData.setOwner1(this.cpToken.address, ucacId2, admin1, {from: parent}).should.be.fulfilled;
            await this.stakeData.setOwner2(this.cpToken.address, ucacId2, admin2, {from: parent}).should.be.fulfilled;
            const addr2 = await this.stakeData.getUcacAddr(this.cpToken.address, ucacId2).should.be.fulfilled;
            addr2.should.be.bignumber.equal(web3.toBigNumber(3));
            const owner1_2 = await this.stakeData.getOwner1(this.cpToken.address, ucacId2).should.be.fulfilled;
            owner1_2.should.be.bignumber.equal(admin1);
            const owner2_2 = await this.stakeData.getOwner2(this.cpToken.address, ucacId2).should.be.fulfilled;
            owner2_2.should.be.bignumber.equal(admin2);

            // ### testing isOwner
            const isOwnerT3 = await this.stakeData.isOwner(this.cpToken.address, ucacId2, admin1).should.be.fulfilled;
            assert(isOwnerT3, "admit1 is an owner of ucacId2");
            const isOwnerT4 = await this.stakeData.isOwner(this.cpToken.address, ucacId2, parent).should.be.fulfilled;
            assert(!isOwnerT4, "parent is not an owner of ucacId2");
        });

    });

    describe("Stake tokens", () => {

        beforeEach(async function() {
            await this.stakeData.setToken(this.cpToken.address, {from: admin1}).should.be.fulfilled;
            // mint some tokens to admin1, admin2
            await this.cpToken.mint(admin1, h.toWei(1000));
            await this.cpToken.mint(admin1, h.toWei(2000));
            await this.cpToken.finishMinting();
            await this.cpToken.endSale();
        });

        it("allows user to stake and unstake; after token switch, allows users to unstake old tokens", async function() {
            await this.cpToken.approve(this.stakeData.address, h.toWei(10), {from: admin1}).should.be.fulfilled;
            // stake tokens
            await this.stakeData.stakeTokens(ucacId1, admin1, h.toWei(10), {from: parent}).should.be.fulfilled;

            // staked tokens should = 10
            const stakedTokens = await this.stakeData.stakedTokensMap(this.cpToken.address, admin1, ucacId1).should.be.fulfilled;
            stakedTokens.should.be.bignumber.equal(h.toWei(10));

            // unstake tokens
            await this.stakeData.unstakeTokens(this.cpToken.address, ucacId1, h.toWei(5), {from: admin1}).should.be.fulfilled;
            // staked tokens should = 5
            const stakedTokens2 = await this.stakeData.stakedTokensMap(this.cpToken.address, admin1, ucacId1).should.be.fulfilled;
            stakedTokens2.should.be.bignumber.equal(h.toWei(5));
        });

        it("allows multiple users to stake and unstake", async function() {
            await this.cpToken.approve(this.stakeData.address, h.toWei(10), {from: admin1}).should.be.fulfilled;
            await this.stakeData.stakeTokens(ucacId1, admin1, h.toWei(10), {from: parent}).should.be.fulfilled;
        });
    });

});
