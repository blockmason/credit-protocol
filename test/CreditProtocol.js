var h = require("./helpers/helpers");

const should = require('chai')
          .use(require('chai-as-promised'))
          .use(require('chai-bignumber')(web3.BigNumber))
          .should();

const CreditProtocol = artifacts.require('./CreditProtocol.sol');
const CPToken = artifacts.require('tce-contracts/contracts/CPToken.sol');
const BasicUCAC = artifacts.require('./BasicUCAC.sol');

const usd = web3.fromAscii("USD");
const testMemo = web3.fromAscii("test1")
const creationStake = web3.toBigNumber(web3.toWei(3500));
const mintAmount = web3.toBigNumber(web3.toWei(20000));

contract('CreditProtocolTest', function([admin, p1, p2]) {

    before(async function() {
        // Advance to the next block to correctly read time in the solidity
        // "now" function interpreted by testrpc
        await h.advanceBlock();
    });

    beforeEach(async function() {
        this.latestTime = h.latestTime();
        this.cpToken = await CPToken.new({from: admin});
        this.creditProtocol =
            await CreditProtocol.new( this.cpToken.address
                                    , web3.toBigNumber(2 * 10 ** 9)
                                    , web3.toWei(0.8)
                                    , {from: admin});
        this.basicUCAC = await BasicUCAC.new({from: admin});

        await this.cpToken.mint(admin, web3.toWei(20000));
        await this.cpToken.mint(p1, web3.toWei(20000));
        await this.cpToken.mint(p2, web3.toWei(20000));
        await this.cpToken.finishMinting();
        await this.cpToken.endSale();
    });

    describe("Staking", () => {

        it("`stakeTokens` stakes appropriate number of tokens for initialized ucacs", async function() {
            const postCreationStake = web3.toBigNumber(web3.toWei(100));
            await this.cpToken.approve( this.creditProtocol.address
                                      , creationStake
                                      , {from: p1}).should.be.fulfilled;
            // stakeTokens call rejected prior to initialization
            await this.creditProtocol.stakeTokens(this.basicUCAC.address, creationStake, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            await this.creditProtocol.createAndStakeUcac(this.basicUCAC.address, usd, creationStake, {from: p1}).should.be.fulfilled;
            await this.cpToken.approve( this.creditProtocol.address
                                      , postCreationStake
                                      , {from: p1}).should.be.fulfilled;
            // stakeTokens call successful post-initialization
            await this.creditProtocol.stakeTokens(this.basicUCAC.address, postCreationStake, {from: p1}).should.be.fulfilled;
            const a = await this.creditProtocol.ucacs(this.basicUCAC.address).should.be.fulfilled;
            a[1].should.be.bignumber.equal(creationStake.add(postCreationStake));
            // tokens can be unstaked
            await this.creditProtocol.unstakeTokens(this.basicUCAC.address, postCreationStake, {from: p1}).should.be.fulfilled;
            const b = await this.creditProtocol.ucacs(this.basicUCAC.address).should.be.fulfilled;
            b[1].should.be.bignumber.equal(creationStake);
            const userTokens = await this.cpToken.balanceOf(p1);
            userTokens.should.be.bignumber.equal(mintAmount.sub(creationStake));
        });

    });

    describe("Debt Creation", () => {
        it("allows two parties to sign a message and issue a debt", async function() {
            // initialize UCAC with minimum staking amount
            await this.cpToken.approve(this.creditProtocol.address, web3.toWei(1), {from: p1}).should.be.fulfilled;
            let txReciept = await this.creditProtocol.createAndStakeUcac(this.basicUCAC.address, usd, web3.toWei(1), {from: p1}).should.be.fulfilled;
            assert.equal(txReciept.logs[0].event, "UcacCreation", "Expected UcacCreation event");
            assert.equal(txReciept.logs[0].args.ucac, this.basicUCAC.address, "Incorrect ucacAddr logged");

            let nonce = p1 < p2 ? await this.creditProtocol.nonces(p1, p2) : await this.creditProtocol.nonces(p2, p1);
            nonce.should.be.bignumber.equal(0);
            nonce = h.bignumToHexString(nonce);
            let amount = h.bignumToHexString(10);
            let content = h.creditHash(this.basicUCAC.address, p1, p2, amount, nonce)
            let sig1 = h.sign(p1, content);
            let sig2 = h.sign(p2, content);
            txReciept = await this.creditProtocol.issueCredit( this.basicUCAC.address, p1, p2, amount
                                           , [ sig1.r, sig1.s, sig1.v ]
                                           , [ sig2.r, sig2.s, sig2.v ]
                                           , testMemo
                                           , {from: p1}).should.be.fulfilled;
            assert.equal(txReciept.logs[0].event, "IssueCredit", "Expected Issue Debt event");
            assert.equal(txReciept.logs[0].args.debtor, p2, "Incorrect debtor logged");
            assert.equal(txReciept.logs[0].args.creditor, p1, "Incorrect creditor logged");
            assert.equal(txReciept.logs[0].args.ucac, this.basicUCAC.address, "Incorrect ucac logged");
            assert.equal(txReciept.logs[0].args.memo, h.fillBytes32(testMemo), "Incorrect memo logged");

            let debtCreated = await this.creditProtocol.balances(this.basicUCAC.address, p1);
            debtCreated.should.be.bignumber.equal(web3.toBigNumber(amount));
            let debtCreated2 = await this.creditProtocol.balances(this.basicUCAC.address, p2);
            debtCreated2.should.be.bignumber.equal(web3.toBigNumber(amount).neg());

            // create 2nd debt
            nonce = p1 < p2 ? await this.creditProtocol.nonces(p1, p2) : await this.creditProtocol.nonces(p2, p1);
            nonce.should.be.bignumber.equal(1);
            nonce = h.bignumToHexString(nonce);
            content = h.creditHash(this.basicUCAC.address, p1, p2, amount, nonce);
            sig1 = h.sign(p1, content);
            sig2 = h.sign(p2, content);
            txReciept = await this.creditProtocol.issueCredit( this.basicUCAC.address, p1, p2, amount
                                           , [ sig1.r, sig1.s, sig1.v ]
                                           , [ sig2.r, sig2.s, sig2.v ]
                                           , testMemo, {from: p1}).should.be.fulfilled;
            assert.equal(txReciept.logs[0].event, "IssueCredit", "Expected Issue Debt event");
            debtCreated = await this.creditProtocol.balances(this.basicUCAC.address, p1);
            debtCreated.should.be.bignumber.equal(web3.toBigNumber(amount).mul(2));
            debtCreated2 = await this.creditProtocol.balances(this.basicUCAC.address, p2);
            debtCreated2.should.be.bignumber.equal(web3.toBigNumber(amount).mul(2).neg());
            // fail to create 3rd debt
            nonce = p1 < p2 ? await this.creditProtocol.nonces(p1, p2) : await this.creditProtocol.nonces(p2, p1);
            nonce.should.be.bignumber.equal(2);
            nonce = h.bignumToHexString(nonce);
            content = h.creditHash(this.basicUCAC.address, p1, p2, amount, nonce);
            sig1 = h.sign(p1, content);
            sig2 = h.sign(p2, content);
            // tx per hour = 2, so a 3rd should fail
            await this.creditProtocol.issueCredit( this.basicUCAC.address, p1, p2, amount
                                           , [ sig1.r, sig1.s, sig1.v ]
                                           , [ sig2.r, sig2.s, sig2.v ]
                                           , testMemo, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            debtCreated = await this.creditProtocol.balances(this.basicUCAC.address, p1);
            debtCreated.should.be.bignumber.equal(web3.toBigNumber(amount).mul(2));
            debtCreated2 = await this.creditProtocol.balances(this.basicUCAC.address, p2);
            debtCreated2.should.be.bignumber.equal(web3.toBigNumber(amount).mul(2).neg());
        });
    });

    describe("txLevel decay", () => {
        beforeEach(async function() {
            await this.cpToken.approve(this.creditProtocol.address, web3.toWei(1), {from: p1}).should.be.fulfilled;
            await this.creditProtocol.createAndStakeUcac( this.basicUCAC.address, usd
                                                        , web3.toWei(1), {from: p1}).should.be.fulfilled;
        });

        it("as time passes, txLevel decays as expected", async function() {
            // do one tx
            let nonce = p1 < p2 ? await this.creditProtocol.nonces(p1, p2) : await this.creditProtocol.nonces(p2, p1);
            nonce = h.bignumToHexString(nonce);
            let amount = h.bignumToHexString(10);
            let content = h.creditHash(this.basicUCAC.address, p1, p2, amount, nonce);
            let sig1 = h.sign(p1, content);
            let sig2 = h.sign(p2, content);
            let txReciept = await this.creditProtocol.issueCredit( this.basicUCAC.address, p1, p2, amount
                                           , [ sig1.r, sig1.s, sig1.v ]
                                           , [ sig2.r, sig2.s, sig2.v ]
                                           , testMemo, {from: p1}).should.be.fulfilled;
            let txLevel = await this.creditProtocol.currentTxLevel(this.basicUCAC.address).should.be.fulfilled;
            txLevel.should.be.bignumber.equal(web3.toWei(0.5));


            // 30 minutes pass, txLevel should be less than totalTokensStaked / 2
            await h.increaseTimeTo(this.latestTime + h.duration.minutes(30));
            txLevel = await this.creditProtocol.currentTxLevel(this.basicUCAC.address).should.be.fulfilled;
            txLevel.should.be.bignumber.lt(web3.toWei(0.25));

            // 1 hour passes, txLevel should = 0
            await h.increaseTimeTo(this.latestTime + h.duration.hours(1));
            txLevel = await this.creditProtocol.currentTxLevel(this.basicUCAC.address).should.be.fulfilled;
            txLevel.should.be.bignumber.equal(0);
        });

        it("if a user unstakes tokens s.t. txLevel > totalStakedTokens, txs are rejected", async function() {
            // do one tx
            await h.makeTransaction(this.creditProtocol, this.basicUCAC.address, p1, p2, web3.toBigNumber(10));
            let txLevel = await this.creditProtocol.currentTxLevel(this.basicUCAC.address).should.be.fulfilled;
            txLevel.should.be.bignumber.equal(web3.toWei(0.5));

            // user unstakes 0.1 tokens
            await this.creditProtocol.unstakeTokens(this.basicUCAC.address, web3.toWei(0.1), {from: p1}).should.be.fulfilled;

            // user is unable to perform an additional tx

            let nonce = p1 < p2 ? await this.creditProtocol.nonces(p1, p2) : await this.creditProtocol.nonces(p2, p1);
            nonce.should.be.bignumber.equal(1);
            nonce = h.bignumToHexString(nonce);
            let amount = h.bignumToHexString(10);
            let content = h.creditHash(this.basicUCAC.address, p1, p2, amount, nonce);
            let sig1 = h.sign(p1, content);
            let sig2 = h.sign(p2, content);
            await this.creditProtocol.issueCredit( this.basicUCAC.address, p1, p2, amount
                                           , [ sig1.r, sig1.s, sig1.v ]
                                           , [ sig2.r, sig2.s, sig2.v ]
                                           , testMemo, {from: p1}).should.be.rejectedWith(h.EVMThrow);
        });

        it("if a user unstakes tokens s.t. tokensToOwnUcac > totalStakedTokens, txs are rejected", async function() {
           // user unstakes 0.1 tokens
            await this.creditProtocol.unstakeTokens(this.basicUCAC.address, web3.toWei(0.25), {from: p1}).should.be.fulfilled;

            // user is unable to perform an additional tx

            let nonce = p1 < p2 ? await this.creditProtocol.nonces(p1, p2) : await this.creditProtocol.nonces(p2, p1);
            nonce = h.bignumToHexString(nonce);
            let amount = h.bignumToHexString(10);
            let content = h.creditHash(this.basicUCAC.address, p1, p2, amount, nonce);
            let sig1 = h.sign(p1, content);
            let sig2 = h.sign(p2, content);
            await this.creditProtocol.issueCredit( this.basicUCAC.address, p1, p2, amount
                                           , [ sig1.r, sig1.s, sig1.v ]
                                           , [ sig2.r, sig2.s, sig2.v ]
                                           , testMemo, {from: p1}).should.be.rejectedWith(h.EVMThrow);
        });


        it("if txLevel > totalStakedTokens, user can stake more tokens and then successfully tx", async function() {
            // two txs are performed (the max given 1 staked token)
            await h.makeTransaction(this.creditProtocol, this.basicUCAC.address, p1, p2, web3.toBigNumber(10));
            await h.makeTransaction(this.creditProtocol, this.basicUCAC.address, p1, p2, web3.toBigNumber(10));

            // user fails to perform an additional tx
            let amount = h.bignumToHexString(3258);
            let nonce = p1 < p2 ? await this.creditProtocol.nonces(p1, p2) : await this.creditProtocol.nonces(p2, p1);
            nonce.should.be.bignumber.equal(2);
            nonce = h.bignumToHexString(nonce);
            let content = h.creditHash(this.basicUCAC.address, p1, p2, amount, nonce);
            let sig1 = h.sign(p1, content);
            let sig2 = h.sign(p2, content);
            let txReciept = await this.creditProtocol.issueCredit( this.basicUCAC.address, p1, p2, amount
                                           , [ sig1.r, sig1.s, sig1.v ]
                                           , [ sig2.r, sig2.s, sig2.v ]
                                           , testMemo, {from: p1}).should.be.rejectedWith(h.EVMThrow);

            // user stakes 0.5 additional tokens
            await this.cpToken.approve(this.creditProtocol.address, web3.toWei(0.5), {from: p1}).should.be.fulfilled;
            await this.creditProtocol.stakeTokens(this.basicUCAC.address, web3.toWei(0.5), {from: p1}).should.be.fulfilled;

            // user successfully performs and addtional tx
            nonce = p1 < p2 ? await this.creditProtocol.nonces(p1, p2) : await this.creditProtocol.nonces(p2, p1);
            nonce.should.be.bignumber.equal(2);
            nonce = h.bignumToHexString(nonce);
            content = h.creditHash(this.basicUCAC.address, p1, p2, amount, nonce);
            sig1 = h.sign(p1, content);
            sig2 = h.sign(p2, content);
            txReciept = await this.creditProtocol.issueCredit( this.basicUCAC.address, p1, p2, amount
                                       , [ sig1.r, sig1.s, sig1.v ]
                                       , [ sig2.r, sig2.s, sig2.v ]
                                       , testMemo, {from: p1}).should.be.fulfilled;
        });

    });

    describe("more txLevel decay", () => {

        beforeEach(async function() {
            await this.cpToken.approve(this.creditProtocol.address, web3.toWei(2), {from: p1}).should.be.fulfilled;
            await this.creditProtocol.createAndStakeUcac( this.basicUCAC.address, usd
                                                        , web3.toWei(2), {from: p1}).should.be.fulfilled;
        });

        it("precise txLevel decay tests with chaning decay rates due to staking & unstaking", async function() {
            await h.makeTransaction(this.creditProtocol, this.basicUCAC.address, p1, p2, web3.toBigNumber(10));
            await h.makeTransaction(this.creditProtocol, this.basicUCAC.address, p1, p2, web3.toBigNumber(10));
            await h.makeTransaction(this.creditProtocol, this.basicUCAC.address, p1, p2, web3.toBigNumber(10));
            let txLevel = await this.creditProtocol.currentTxLevel(this.basicUCAC.address).should.be.fulfilled;
            txLevel.should.be.bignumber.gt(web3.toBigNumber(web3.toWei(1.5)).sub(web3.toWei(0.001)));
            txLevel.should.be.bignumber.lt(web3.toBigNumber(web3.toWei(1.5)).add(web3.toWei(0.001)));

            // 30 minutes pass, txLevel should be roughly equal to (1 / 4) * totalTokensStaked.
            await h.increaseTimeTo(this.latestTime + h.duration.minutes(30));
            txLevel = await this.creditProtocol.currentTxLevel(this.basicUCAC.address).should.be.fulfilled;
            txLevel.should.be.bignumber.gt(web3.toBigNumber(web3.toWei(0.5)).sub(web3.toWei(0.001)));
            txLevel.should.be.bignumber.lt(web3.toBigNumber(web3.toWei(0.5)).add(web3.toWei(0.001)));

            // 1 hour passes, txLevel should = 0
            await h.increaseTimeTo(this.latestTime + h.duration.hours(1));
            txLevel = await this.creditProtocol.currentTxLevel(this.basicUCAC.address).should.be.fulfilled;
            txLevel.should.be.bignumber.equal(0);

            // max out txLevel with four transactions
            await h.makeTransaction(this.creditProtocol, this.basicUCAC.address, p1, p2, web3.toBigNumber(10));
            await h.makeTransaction(this.creditProtocol, this.basicUCAC.address, p1, p2, web3.toBigNumber(10));
            await h.makeTransaction(this.creditProtocol, this.basicUCAC.address, p1, p2, web3.toBigNumber(10));
            await h.makeTransaction(this.creditProtocol, this.basicUCAC.address, p1, p2, web3.toBigNumber(10));
            txLevel = await this.creditProtocol.currentTxLevel(this.basicUCAC.address).should.be.fulfilled;

            // txLevel should be maxed out
            txLevel.should.be.bignumber.gt(web3.toBigNumber(web3.toWei(2)).sub(web3.toWei(0.001)));
            txLevel.should.be.bignumber.lte(web3.toBigNumber(web3.toWei(2)));

            // decay for 30 minutes at normal rate
            await h.increaseTimeTo(this.latestTime + h.duration.minutes(90));
            txLevel = await this.creditProtocol.currentTxLevel(this.basicUCAC.address).should.be.fulfilled;
            txLevel.should.be.bignumber.gt(web3.toBigNumber(web3.toWei(1)).sub(web3.toWei(0.001)));
            txLevel.should.be.bignumber.lt(web3.toBigNumber(web3.toWei(1)).add(web3.toWei(0.001)));

            // double amount of staked tokens
            await this.cpToken.approve( this.creditProtocol.address
                                      , web3.toWei(2)
                                      , {from: p1}).should.be.fulfilled;
            // stakeTokens call successful post-initialization
            await this.creditProtocol.stakeTokens(this.basicUCAC.address, web3.toWei(2), {from: p1}).should.be.fulfilled;

            // advance 15 minutes and show that txLevel has hit 0
            await h.increaseTimeTo(this.latestTime + h.duration.minutes(105));
            txLevel = await this.creditProtocol.currentTxLevel(this.basicUCAC.address).should.be.fulfilled;
            txLevel.should.be.bignumber.equal(0);
        });
    });
});
