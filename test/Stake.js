var h = require("./helpers/helpers");

const should = require('chai')
          .use(require('chai-as-promised'))
          .use(require('chai-bignumber')(h.BigNumber))
          .should();

const CPToken = artifacts.require('tce-contracts/contracts/CPToken.sol');
const Stake = artifacts.require('./Stake.sol');

const ucacId1 = web3.sha3("hi");
const ucacId2 = web3.sha3("yo");

contract('StakeTest', function([admin, p1, p2, ucacAddr]) {

    before(async function() {
    });

    beforeEach(async function() {
        this.cpToken = await CPToken.new({from: admin});
        this.stake = await Stake.new( this.cpToken.address, web3.toBigNumber(2)
                                    , web3.toBigNumber(1), {from: admin});
        await this.cpToken.mint(p1, h.toWei(20000));
        await this.cpToken.mint(p2, h.toWei(20000));
        await this.cpToken.finishMinting();
        await this.cpToken.endSale();
    });

    describe("Staking", () => {
        it("stakeTokens stakes appropriate number of tokens for initialized ucacs", async function() {
            const creationStake = web3.toBigNumber(web3.toWei(3500));
            const postCreationStake = web3.toBigNumber(web3.toWei(100));
            await this.cpToken.approve( this.stake.address
                                      , creationStake.add(postCreationStake)
                                      , {from: p1}).should.be.fulfilled;
            // stakeTokens call rejected prior to initialization
            await this.stake.stakeTokens(ucacId2, p1, postCreationStake, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.stake.createAndStakeUcac(ucacAddr, ucacId2, creationStake, {from: p1}).should.be.fulfilled;
            // // stakeTokens call successful post-initialization
            // await this.stake.stakeTokens(ucacId2, postCreationStake, {from: p1}).should.be.fulfilled;
            // const a = await this.stake.ucacStatus(ucacId2).should.be.fulfilled;
            // a[0].should.be.bignumber.equal(creationStake.add(postCreationStake));
        });
    });

});
