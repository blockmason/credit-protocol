var h = require("./helpers/helpers");

const should = require('chai')
          .use(require('chai-as-promised'))
          .use(require('chai-bignumber')(web3.BigNumber))
          .should();

const CPToken = artifacts.require('tce-contracts/contracts/CPToken.sol');
const Stake = artifacts.require('./Stake.sol');

const usd = web3.fromAscii("USD");
const ucacId1 = web3.sha3("hi");
const ucacId2 = web3.sha3("yo");
const creationStake = web3.toBigNumber(web3.toWei(3500));
const mintAmount = web3.toBigNumber(web3.toWei(20000))

contract('StakeTest', function([admin, p1, p2, ucacAddr, ucacAddr2]) {

    before(async function() {
    });

    beforeEach(async function() {
        this.cpToken = await CPToken.new({from: admin});
        this.stake = await Stake.new( this.cpToken.address, web3.toBigNumber(2)
                                    , web3.toBigNumber(1), {from: admin});
        await this.cpToken.mint(p1, mintAmount);
        await this.cpToken.mint(p2, mintAmount);
        await this.cpToken.finishMinting();
        await this.cpToken.endSale();
    });

    describe("Staking", () => {

        it("`stakeTokens` stakes appropriate number of tokens for initialized ucacs", async function() {
            const postCreationStake = web3.toBigNumber(web3.toWei(100));
            await this.cpToken.approve( this.stake.address
                                      , creationStake
                                      , {from: p1}).should.be.fulfilled;
            // stakeTokens call rejected prior to initialization
            await this.stake.stakeTokens(ucacId2, p1, creationStake, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.stake.createAndStakeUcac(ucacAddr, ucacId2, usd, creationStake, {from: p1}).should.be.fulfilled;
            await this.cpToken.approve( this.stake.address
                                      , postCreationStake
                                      , {from: p1}).should.be.fulfilled;
            // stakeTokens call successful post-initialization
            await this.stake.stakeTokens(ucacId2, p1, postCreationStake, {from: p1}).should.be.fulfilled;
            const a = await this.stake.ucacs(ucacId2).should.be.fulfilled;
            a[1].should.be.bignumber.equal(creationStake.add(postCreationStake));
            // tokens can be unstaked
            await this.stake.unstakeTokens(ucacId2, postCreationStake, {from: p1}).should.be.fulfilled;
            const b = await this.stake.ucacs(ucacId2).should.be.fulfilled;
            b[1].should.be.bignumber.equal(creationStake);
            const userTokens = await this.cpToken.balanceOf(p1);
            userTokens.should.be.bignumber.equal(mintAmount.sub(creationStake));
        });

    });


});
