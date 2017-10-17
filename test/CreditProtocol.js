var h = require("./helpers/helpers");

const should = require('chai')
          .use(require('chai-as-promised'))
          .use(require('chai-bignumber')(web3.BigNumber))
          .should();

const CreditProtocol = artifacts.require('./CreditProtocol.sol');
const CPToken = artifacts.require('tce-contracts/contracts/CPToken.sol');
const BasicUCAC = artifacts.require('./BasicUCAC.sol');
const Stake = artifacts.require('./Stake.sol');

const usd = web3.fromAscii("USD");
const ucacId1 = web3.sha3("hi");
const ucacId2 = web3.sha3("yo");

function sign(signer, content) {
    let contentHash = web3.sha3(content, {encoding: 'hex'});
    let sig = web3.eth.sign(signer, contentHash, {encoding: 'hex'});
    sig = sig.substr(2, sig.length);

    let res = {};
    res.r = "0x" + sig.substr(0, 64);
    res.s = "0x" + sig.substr(64, 64);
    res.v = web3.toDecimal("0x" + sig.substr(128, 2));

    if (res.v < 27) res.v += 27;

    return res;
}

function bignumToHexString(num) {
    const a = num.toString(16);
    return "0x" + '0'.repeat(64 - a.length) + a;
}

async function makeTransaction(cp, ucacId, creditor, debtor, _amount) {
    let nonce = creditor < debtor ? await cp.nonces(creditor, debtor) : await cp.nonces(debtor, creditor);
    nonce = bignumToHexString(nonce);
    let amount = bignumToHexString(_amount);
    let content1 = ucacId + creditor.substr(2, creditor.length) + debtor.substr(2, debtor.length)
                          + amount.substr(2, amount.length) + nonce.substr(2, nonce.length);
    let sig1 = sign(creditor, content1);
    let content2 = ucacId + creditor.substr(2, creditor.length) + debtor.substr(2, debtor.length)
                          + amount.substr(2, amount.length) + nonce.substr(2, nonce.length);
    let sig2 = sign(debtor, content2);
    let txReciept = await cp.issueCredit( ucacId, creditor, debtor, amount
                                   , sig1.r, sig1.s, sig1.v
                                   , sig2.r, sig2.s, sig2.v, {from: creditor});
    return txReciept;
}

contract('CreditProtocolTest', function([admin, p1, p2, ucacAddr]) {

    before(async function() {
        // Advance to the next block to correctly read time in the solidity
        // "now" function interpreted by testrpc
        await h.advanceBlock();
    });

    beforeEach(async function() {
        this.latestTime = h.latestTime();
        this.cpToken = await CPToken.new({from: admin});
        this.stake = await Stake.new( this.cpToken.address, web3.toBigNumber(2)
                                    , web3.toBigNumber(1), {from: admin});
        this.creditProtocol = await CreditProtocol.new(this.stake.address, {from: admin});
        this.basicUCAC = await BasicUCAC.new({from: admin});

        await this.cpToken.mint(admin, web3.toWei(20000));
        await this.cpToken.mint(p1, web3.toWei(20000));
        await this.cpToken.mint(p2, web3.toWei(20000));
        await this.cpToken.finishMinting();
        await this.cpToken.endSale();
    });

    describe("Debt Creation", () => {
        it("allows two parties to sign a message and issue a debt", async function() {
            // initialize UCAC with minimum staking amount
            await this.cpToken.approve(this.stake.address, web3.toWei(1), {from: p1}).should.be.fulfilled;
            await this.stake.createAndStakeUcac(this.basicUCAC.address, ucacId1, usd, web3.toWei(1), {from: p1}).should.be.fulfilled;
            let nonce = p1 < p2 ? await this.creditProtocol.nonces(p1, p2) : await this.creditProtocol.nonces(p2, p1);
            nonce.should.be.bignumber.equal(0);
            nonce = bignumToHexString(nonce);
            let amount = '0x000000000000000000000000000000000000000000000000000000000000000a';
            let content1 = ucacId1 + p1.substr(2, p1.length) + p2.substr(2, p2.length)
                                     + amount.substr(2, amount.length) + nonce.substr(2, nonce.length);
            let sig1 = sign(p1, content1);
            let content2 = ucacId1 + p1.substr(2, p1.length) + p2.substr(2, p2.length)
                                     + amount.substr(2, amount.length) + nonce.substr(2, nonce.length);
            let sig2 = sign(p2, content2);
            let txReciept = await this.creditProtocol.issueCredit( ucacId1, p1, p2, amount
                                           , sig1.r, sig1.s, sig1.v
                                           , sig2.r, sig2.s, sig2.v, {from: p1}).should.be.fulfilled;
            assert.equal(txReciept.logs[0].event, "IssueCredit", "Expected Issue Debt event");
            assert.equal(txReciept.logs[0].args.debtor, p2, "Incorrect debtor logged");
            assert.equal(txReciept.logs[0].args.creditor, p1, "Incorrect creditor logged");
            assert.equal(txReciept.logs[0].args.ucac, ucacId1, "Incorrect ucac logged");

            let debtCreated = await this.creditProtocol.balances(ucacId1, p1);
            debtCreated.should.be.bignumber.equal(web3.toBigNumber(amount));
            let debtCreated2 = await this.creditProtocol.balances(ucacId1, p2);
            debtCreated2.should.be.bignumber.equal(web3.toBigNumber(amount).neg());

            // create 2nd debt
            nonce = p1 < p2 ? await this.creditProtocol.nonces(p1, p2) : await this.creditProtocol.nonces(p2, p1);
            nonce.should.be.bignumber.equal(1);
            nonce = bignumToHexString(nonce);
            content1 = ucacId1 + p1.substr(2, p1.length) + p2.substr(2, p2.length)
                                 + amount.substr(2, amount.length) + nonce.substr(2, nonce.length);
            sig1 = sign(p1, content1);
            content2 = ucacId1 + p1.substr(2, p1.length) + p2.substr(2, p2.length)
                                 + amount.substr(2, amount.length) + nonce.substr(2, nonce.length);
            sig2 = sign(p2, content2);
            txReciept = await this.creditProtocol.issueCredit( ucacId1, p1, p2, amount
                                           , sig1.r, sig1.s, sig1.v
                                           , sig2.r, sig2.s, sig2.v, {from: p1}).should.be.fulfilled;
            assert.equal(txReciept.logs[0].event, "IssueCredit", "Expected Issue Debt event");
            debtCreated = await this.creditProtocol.balances(ucacId1, p1);
            debtCreated.should.be.bignumber.equal(web3.toBigNumber(amount).mul(2));
            debtCreated2 = await this.creditProtocol.balances(ucacId1, p2);
            debtCreated2.should.be.bignumber.equal(web3.toBigNumber(amount).mul(2).neg());
            // fail to create 3rd debt
            nonce = p1 < p2 ? await this.creditProtocol.nonces(p1, p2) : await this.creditProtocol.nonces(p2, p1);
            nonce.should.be.bignumber.equal(2);
            nonce = bignumToHexString(nonce);
            content1 = ucacId1 + p1.substr(2, p1.length) + p2.substr(2, p2.length)
                                 + amount.substr(2, amount.length) + nonce.substr(2, nonce.length);
            sig1 = sign(p1, content1);
            content2 = ucacId1 + p1.substr(2, p1.length) + p2.substr(2, p2.length)
                                 + amount.substr(2, amount.length) + nonce.substr(2, nonce.length);
            sig2 = sign(p2, content2);
            // tx per hour = 2, so a 3rd should fail
            await this.creditProtocol.issueCredit( ucacId1, p1, p2, amount
                                           , sig1.r, sig1.s, sig1.v
                                           , sig2.r, sig2.s, sig2.v, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            debtCreated = await this.creditProtocol.balances(ucacId1, p1);
            debtCreated.should.be.bignumber.equal(web3.toBigNumber(amount).mul(2));
            debtCreated2 = await this.creditProtocol.balances(ucacId1, p2);
            debtCreated2.should.be.bignumber.equal(web3.toBigNumber(amount).mul(2).neg());
        });
    });

    describe("txLevel decay", () => {
        beforeEach(async function() {
            await this.cpToken.approve(this.stake.address, web3.toWei(1), {from: p1}).should.be.fulfilled;
            await this.stake.createAndStakeUcac( this.basicUCAC.address
                                               , ucacId1, usd, web3.toWei(1), {from: p1}).should.be.fulfilled;
        });

        it("as time passes, txLevel decays as expected", async function() {
            // do one tx
            let nonce = p1 < p2 ? await this.creditProtocol.nonces(p1, p2) : await this.creditProtocol.nonces(p2, p1);
            nonce = bignumToHexString(nonce);
            let amount = '0x000000000000000000000000000000000000000000000000000000000000000a';
            let content1 = ucacId1 + p1.substr(2, p1.length) + p2.substr(2, p2.length)
                                     + amount.substr(2, amount.length) + nonce.substr(2, nonce.length);
            let sig1 = sign(p1, content1);
            let content2 = ucacId1 + p1.substr(2, p1.length) + p2.substr(2, p2.length)
                                     + amount.substr(2, amount.length) + nonce.substr(2, nonce.length);
            let sig2 = sign(p2, content2);
            let txReciept = await this.creditProtocol.issueCredit( ucacId1, p1, p2, amount
                                           , sig1.r, sig1.s, sig1.v
                                           , sig2.r, sig2.s, sig2.v, {from: p1}).should.be.fulfilled;
            let txLevel = await this.stake.currentTxLevel(ucacId1).should.be.fulfilled;
            txLevel.should.be.bignumber.equal(web3.toWei(0.5));


            // 30 minutes pass, txLevel should be less than totalTokensStaked / 2
            await h.increaseTimeTo(this.latestTime + h.duration.minutes(30));
            txLevel = await this.stake.currentTxLevel(ucacId1).should.be.fulfilled;
            txLevel.should.be.bignumber.lt(web3.toWei(0.25));

            // 1 hour passes, txLevel should = 0
            await h.increaseTimeTo(this.latestTime + h.duration.hours(1));
            txLevel = await this.stake.currentTxLevel(ucacId1).should.be.fulfilled;
            txLevel.should.be.bignumber.equal(0);
        });

        it("if a user unstakes tokens s.t. txLevel > totalStakedTokens, txs are rejected", async function() {
            let amount = '0x000000000000000000000000000000000000000000000000000000000000000a';

            // do one tx
            await makeTransaction(this.creditProtocol, ucacId1, p1, p2, web3.toBigNumber(10));
            let txLevel = await this.stake.currentTxLevel(ucacId1).should.be.fulfilled;
            txLevel.should.be.bignumber.equal(web3.toWei(0.5));

            // user unstakes 0.1 tokens
            await this.stake.unstakeTokens(ucacId1, web3.toWei(0.1), {from: p1}).should.be.fulfilled;

            // user is unable to perform an additional tx

            nonce = p1 < p2 ? await this.creditProtocol.nonces(p1, p2) : await this.creditProtocol.nonces(p2, p1);
            nonce.should.be.bignumber.equal(1);
            nonce = bignumToHexString(nonce);
            content1 = ucacId1 + p1.substr(2, p1.length) + p2.substr(2, p2.length)
                                 + amount.substr(2, amount.length) + nonce.substr(2, nonce.length);
            sig1 = sign(p1, content1);
            content2 = ucacId1 + p1.substr(2, p1.length) + p2.substr(2, p2.length)
                                 + amount.substr(2, amount.length) + nonce.substr(2, nonce.length);
            sig2 = sign(p2, content2);
            txReciept = await this.creditProtocol.issueCredit( ucacId1, p1, p2, amount
                                           , sig1.r, sig1.s, sig1.v
                                           , sig2.r, sig2.s, sig2.v, {from: p1}).should.be.rejectedWith(h.EVMThrow);
        });

        it("if txLevel > totalStakedTokens, user can stake more tokens and then successfully tx", async function() {
            // two txs are performed (the max given 1 staked token)
            await makeTransaction(this.creditProtocol, ucacId1, p1, p2, web3.toBigNumber(10));
            await makeTransaction(this.creditProtocol, ucacId1, p1, p2, web3.toBigNumber(10));

            // user fails to perform an additional tx
            let amount = '0x0000000000000000000000000000000000000000000000000000000000000cba';
            let nonce = p1 < p2 ? await this.creditProtocol.nonces(p1, p2) : await this.creditProtocol.nonces(p2, p1);
            nonce.should.be.bignumber.equal(2);
            nonce = bignumToHexString(nonce);
            let content1 = ucacId1 + p1.substr(2, p1.length) + p2.substr(2, p2.length)
                                     + amount.substr(2, amount.length) + nonce.substr(2, nonce.length);
            let sig1 = sign(p1, content1);
            let content2 = ucacId1 + p1.substr(2, p1.length) + p2.substr(2, p2.length)
                                     + amount.substr(2, amount.length) + nonce.substr(2, nonce.length);
            let sig2 = sign(p2, content2);
            let txReciept = await this.creditProtocol.issueCredit( ucacId1, p1, p2, amount
                                           , sig1.r, sig1.s, sig1.v
                                           , sig2.r, sig2.s, sig2.v, {from: p1}).should.be.rejectedWith(h.EVMThrow);

            // user stakes 0.5 additional tokens
            await this.cpToken.approve(this.stake.address, web3.toWei(0.5), {from: p1}).should.be.fulfilled;
            await this.stake.stakeTokens(ucacId1, p1, web3.toWei(0.5), {from: p1}).should.be.fulfilled;

            // user successfully performs and addtional tx
            nonce = p1 < p2 ? await this.creditProtocol.nonces(p1, p2) : await this.creditProtocol.nonces(p2, p1);
            nonce.should.be.bignumber.equal(2);
            nonce = bignumToHexString(nonce);
            content1 = ucacId1 + p1.substr(2, p1.length) + p2.substr(2, p2.length)
                                 + amount.substr(2, amount.length) + nonce.substr(2, nonce.length);
            sig1 = sign(p1, content1);
            content2 = ucacId1 + p1.substr(2, p1.length) + p2.substr(2, p2.length)
                                 + amount.substr(2, amount.length) + nonce.substr(2, nonce.length);
            sig2 = sign(p2, content2);
            txReciept = await this.creditProtocol.issueCredit( ucacId1, p1, p2, amount
                                       , sig1.r, sig1.s, sig1.v
                                       , sig2.r, sig2.s, sig2.v, {from: p1}).should.be.fulfilled;
        });
    });
});
