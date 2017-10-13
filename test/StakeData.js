var h = require("./helpers/helpers");

const should = require('chai')
          .use(require('chai-as-promised'))
          .use(require('chai-bignumber')(h.BigNumber))
          .should();

const StakeData = artifacts.require('./StakeData.sol');
const CPToken = artifacts.require('tce-contracts/contracts/CPToken.sol');

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
        this.cpToken = await CPToken.new({from: admin1});
        this.stakeData = await StakeData.new(this.cpToken.address, {from: admin1});
        await this.stakeData.setAdmin2(admin2, {from: admin1});
        await this.stakeData.changeParent(parent, {from: admin1});
    });

    describe("UCAC info and ownership", () => {
        it("allows Ucac info (ucacAddr, owner1, owner2) to be set and reset", async function() {
            // rejects attemps to set UcacAddr by non-parent
            await this.stakeData.setUcacAddr(ucacId1, this.cpToken.address, {from: admin1}).should.be.rejectedWith(h.EVMThrow);

            // ## testing with ucacId1
            await this.stakeData.setUcacAddr(ucacId1, this.cpToken.address, {from: parent}).should.be.fulfilled;
            await this.stakeData.setOwner1(ucacId1, admin1, {from: parent}).should.be.fulfilled;
            await this.stakeData.setOwner2(ucacId1, admin1, {from: parent}).should.be.fulfilled;
            const addr1 = await this.stakeData.ucacs(ucacId1).should.be.fulfilled;
            console.log(addr1);
            addr1.should.be.bignumber.equal(this.cpToken.address);
            const owner1 = await this.stakeData.getUcacAddr(ucacId1).should.be.fulfilled;
            addr1.should.be.bignumber.equal(this.cpToken.address);
            const owner2 = await this.stakeData.getOwner1(ucacId1).should.be.fulfilled;
            addr1.should.be.bignumber.equal(this.cpToken.address);

            // ### testing isOwner
            const isOwnerT1 = await this.stakeData.isUcacOwner(ucacId1, admin1).should.be.fulfilled;
            assert(isOwnerT1, "admin1 is an owner of ucacId2");
            const isOwnerT2 = await this.stakeData.isUcacOwner(ucacId1, admin2).should.be.fulfilled;
            assert(!isOwnerT2, "admin2 is not an owner of ucacId2");

            // ## testing with ucacId2
            await this.stakeData.setUcacAddr(ucacId2, web3.toBigNumber(3), {from: parent}).should.be.fulfilled;
            await this.stakeData.setOwner1(ucacId2, admin1, {from: parent}).should.be.fulfilled;
            await this.stakeData.setOwner2(ucacId2, admin2, {from: parent}).should.be.fulfilled;
            const addr2 = await this.stakeData.getUcacAddr(ucacId2).should.be.fulfilled;
            addr2.should.be.bignumber.equal(web3.toBigNumber(3));
            const owner1_2 = await this.stakeData.getOwner1(ucacId2).should.be.fulfilled;
            owner1_2.should.be.bignumber.equal(admin1);
            const owner2_2 = await this.stakeData.getOwner2(ucacId2).should.be.fulfilled;
            owner2_2.should.be.bignumber.equal(admin2);

            // ### testing isOwner
            const isOwnerT3 = await this.stakeData.isUcacOwner(ucacId2, admin1).should.be.fulfilled;
            assert(isOwnerT3, "admit1 is an owner of ucacId2");
            const isOwnerT4 = await this.stakeData.isUcacOwner(ucacId2, parent).should.be.fulfilled;
            assert(!isOwnerT4, "parent is not an owner of ucacId2");
        });

    });

    describe("Stake tokens", () => {

        beforeEach(async function() {
            // mint some tokens to admin1, admin2
            await this.cpToken.mint(admin1, h.toWei(1000));
            await this.cpToken.mint(admin2, h.toWei(2000));
            await this.cpToken.finishMinting();
            await this.cpToken.endSale();
        });

        it("can't stake tokens without approved spending; can't stake to unapproved stakeHolder", async function() {
            await this.stakeData.stakeTokens(ucacId1, admin1, h.toWei(3), {from: parent}).should.be.rejectedWith(h.EVMThrow);

            await this.cpToken.approve(this.stakeData.address, h.toWei(3), {from: admin1}).should.be.fulfilled;
            await this.stakeData.stakeTokens(ucacId1, admin2, h.toWei(3), {from: parent}).should.be.rejectedWith(h.EVMThrow);

            // stake 3 tokens to ucacId1
            await this.stakeData.stakeTokens(ucacId1, admin1, h.toWei(3), {from: parent}).should.be.fulfilled;
            const stakedTokens0 = await this.stakeData.stakedTokensMap(admin1, ucacId1).should.be.fulfilled;
            stakedTokens0.should.be.bignumber.equal(h.toWei(3));
        });

        it("allows user to stake and unstake", async function() {
            await this.cpToken.approve(this.stakeData.address, h.toWei(10), {from: admin1}).should.be.fulfilled;
            // stake tokens
            await this.stakeData.stakeTokens(ucacId1, admin1, h.toWei(10), {from: parent}).should.be.fulfilled;

            // staked tokens should = 10
            const stakedTokens = await this.stakeData.stakedTokensMap(admin1, ucacId1).should.be.fulfilled;
            stakedTokens.should.be.bignumber.equal(h.toWei(10));

            // unstake tokens
            await this.stakeData.unstakeTokens(ucacId1, h.toWei(5), {from: admin1}).should.be.fulfilled;
            // staked tokens should = 5
            const stakedTokens2 = await this.stakeData.stakedTokensMap(admin1, ucacId1).should.be.fulfilled;
            stakedTokens2.should.be.bignumber.equal(h.toWei(5));

            // unstake full amount of ether allocated on old token contract
            await this.stakeData.unstakeTokens(ucacId1, h.toWei(5), {from: admin1}).should.be.fulfilled;
            // staked tokens should = 0
            const stakedTokens4 = await this.stakeData.stakedTokensMap(admin1, ucacId1).should.be.fulfilled;
            stakedTokens4.should.be.bignumber.equal(0);

            // check that admin1's token balance has be restored to its original
            // quantity (1000)
            const remainingTokens = await this.cpToken.balanceOf(admin1);
            remainingTokens.should.be.bignumber.equal(h.toWei(1000));

            await this.cpToken.approve(this.stakeData.address, h.toWei(3), {from: admin1}).should.be.fulfilled;
            // stake 3 tokens to ucacId2
            await this.stakeData.stakeTokens(ucacId2, admin1, h.toWei(3), {from: parent}).should.be.fulfilled;
            const stakedTokens5 = await this.stakeData.stakedTokensMap(admin1, ucacId2).should.be.fulfilled;
            stakedTokens5.should.be.bignumber.equal(h.toWei(3));
        });

        it("allows multiple users to stake and unstake", async function() {
            // ## admin1 stakes
            await this.cpToken.approve(this.stakeData.address, h.toWei(10), {from: admin1}).should.be.fulfilled;
            // ### non-parent should be unable to stake
            await this.stakeData.stakeTokens(ucacId1, admin1, h.toWei(10), {from: admin1}).should.be.rejectedWith(h.EVMThrow);
            await this.stakeData.stakeTokens(ucacId1, admin1, h.toWei(10), {from: parent}).should.be.fulfilled;

            const stakedTokens_0 = await this.stakeData.stakedTokensMap(admin1, ucacId1).should.be.fulfilled;
            stakedTokens_0.should.be.bignumber.equal(h.toWei(10));

            // ## admin2 stakes
            await this.cpToken.approve(this.stakeData.address, h.toWei(10), {from: admin2}).should.be.fulfilled;
            await this.stakeData.stakeTokens(ucacId1, admin2, h.toWei(10), {from: parent}).should.be.fulfilled;

            const stakedTokens_1 = await this.stakeData.stakedTokensMap(admin2, ucacId1).should.be.fulfilled;
            stakedTokens_1.should.be.bignumber.equal(h.toWei(10));
        });

        it("maintains an accurate totalStakedTokens count for multiple UCACs", async function() {
            await this.cpToken.approve(this.stakeData.address, h.toWei(500), {from: admin1}).should.be.fulfilled;
            // stake 10 tokens to ucacId1
            await this.stakeData.stakeTokens(ucacId1, admin1, h.toWei(10), {from: parent}).should.be.fulfilled;

            // ucacId1.totalStakedTokens = 10
            const totalStakedTokens_0 = await this.stakeData.getTotalStakedTokens(ucacId1).should.be.fulfilled;
            totalStakedTokens_0.should.be.bignumber.equal(h.toWei(10));

            // stake 3 tokens to ucacId2
            await this.stakeData.stakeTokens(ucacId2, admin1, h.toWei(3), {from: parent}).should.be.fulfilled;

            // ucacId2.totalStakedTokens = 3
            const totalStakedTokens_1 = await this.stakeData.getTotalStakedTokens(ucacId2).should.be.fulfilled;
            totalStakedTokens_1.should.be.bignumber.equal(h.toWei(3));

            // stake 5 tokens to ucacId2
            await this.stakeData.stakeTokens(ucacId2, admin1, h.toWei(5), {from: parent}).should.be.fulfilled;

            // ucacId2.totalStakedTokens = 8
            const totalStakedTokens_2 = await this.stakeData.getTotalStakedTokens(ucacId2).should.be.fulfilled;
            totalStakedTokens_2.should.be.bignumber.equal(h.toWei(8));

            // unstake 1 token from ucacId2
            await this.stakeData.unstakeTokens(ucacId2, h.toWei(1), {from: admin1}).should.be.fulfilled;

            // ucacId2 totalStakedTokens = 7
            const totalStakedTokens_3 = await this.stakeData.getTotalStakedTokens(ucacId2).should.be.fulfilled;
            totalStakedTokens_3.should.be.bignumber.equal(h.toWei(7));
        });

    });

});
