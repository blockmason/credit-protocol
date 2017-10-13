var h = require("./helpers/helpers");

const should = require('chai')
          .use(require('chai-as-promised'))
          .use(require('chai-bignumber')(h.BigNumber))
          .should();

const CreditProtocol = artifacts.require('./CreditProtocol.sol');
const CPToken = artifacts.require('tce-contracts/contracts/CPToken.sol');
const Stake = artifacts.require('./Stake.sol');

const ucacId1 = web3.sha3("hi");
const ucacId2 = web3.sha3("yo");


const sign = function(signer, content) {
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

const hexy = function(num) {
    const a = num.toString(16);
    return "0x" + '0'.repeat(64 - a.length) + a;
}

contract('FriendCreationTest', function([admin, p1, p2, ucacAddr]) {

    before(async function() {
    });

    beforeEach(async function() {
        this.cpToken = await CPToken.new({from: admin});
        this.stake = await Stake.new( this.cpToken.address, web3.toBigNumber(2)
                                    , web3.toBigNumber(1), {from: admin});
        this.creditProtocol = await CreditProtocol.new(this.stake.address, {from: admin});
        await this.cpToken.mint(admin, h.toWei(20000));
        await this.cpToken.mint(p1, h.toWei(20000));
        await this.cpToken.mint(p2, h.toWei(20000));
        await this.cpToken.finishMinting();
        await this.cpToken.endSale();
    });

    describe("Debt Creation", () => {
        it("allows two parties to sign a message and issue a debt", async function() {
            // initialize UCAC with minimum staking amount
            await this.cpToken.approve(this.stake.address, h.toWei(1), {from: p1}).should.be.fulfilled;
            await this.stake.createAndStakeUcac(ucacAddr, ucacId1, h.toWei(1), {from: p1}).should.be.fulfilled;
            let nonce = p1 < p2 ? await this.creditProtocol.nonces(p1, p2) : await this.creditProtocol.nonces(p2, p1);
            nonce.should.be.bignumber.equal(0);
            nonce = hexy(nonce);
            let amount = '0x000000000000000000000000000000000000000000000000000000000000000a';
            let content1 = ucacId1 + p1.substr(2, p1.length) + p2.substr(2, p2.length)
                                     + amount.substr(2, amount.length) + nonce.substr(2, nonce.length);
            let sig1 = sign(p1, content1);
            let content2 = ucacId1 + p1.substr(2, p1.length) + p2.substr(2, p2.length)
                                     + amount.substr(2, amount.length) + nonce.substr(2, nonce.length);
            let sig2 = sign(p2, content2);
            await this.creditProtocol.issueDebt( ucacId1, p1, p2, amount
                                           , sig1.r, sig1.s, sig1.v
                                           , sig2.r, sig2.s, sig2.v, {from: p1}).should.be.fulfilled;
            let debtCreated = await this.creditProtocol.balances(ucacId1, p1);
            debtCreated.should.be.bignumber.equal(web3.toBigNumber(amount));
            let debtCreated2 = await this.creditProtocol.balances(ucacId1, p2);
            debtCreated2.should.be.bignumber.equal(web3.toBigNumber(amount).neg());

            // fail to create a third debt by exceeding TX cap
            nonce = p1 < p2 ? await this.creditProtocol.nonces(p1, p2) : await this.creditProtocol.nonces(p2, p1);
            nonce.should.be.bignumber.equal(1);
            nonce = hexy(nonce);
            content1 = ucacId1 + p1.substr(2, p1.length) + p2.substr(2, p2.length)
                                 + amount.substr(2, amount.length) + nonce.substr(2, nonce.length);
            sig1 = sign(p1, content1);
            content2 = ucacId1 + p1.substr(2, p1.length) + p2.substr(2, p2.length)
                                 + amount.substr(2, amount.length) + nonce.substr(2, nonce.length);
            sig2 = sign(p2, content2);
            await this.creditProtocol.issueDebt( ucacId1, p1, p2, amount
                                           , sig1.r, sig1.s, sig1.v
                                           , sig2.r, sig2.s, sig2.v, {from: p1}).should.be.fulfilled;
            debtCreated = await this.creditProtocol.balances(ucacId1, p1);
            debtCreated.should.be.bignumber.equal(web3.toBigNumber(amount).mul(2));
            debtCreated2 = await this.creditProtocol.balances(ucacId1, p2);
            debtCreated2.should.be.bignumber.equal(web3.toBigNumber(amount).mul(2).neg());
            // can create second debt with different order
            nonce = p1 < p2 ? await this.creditProtocol.nonces(p1, p2) : await this.creditProtocol.nonces(p2, p1);
            nonce.should.be.bignumber.equal(2);
            nonce = hexy(nonce);
            content1 = ucacId1 + p1.substr(2, p1.length) + p2.substr(2, p2.length)
                                 + amount.substr(2, amount.length) + nonce.substr(2, nonce.length);
            sig1 = sign(p1, content1);
            content2 = ucacId1 + p1.substr(2, p1.length) + p2.substr(2, p2.length)
                                 + amount.substr(2, amount.length) + nonce.substr(2, nonce.length);
            sig2 = sign(p2, content2);
            // tx per hour = 2, so a 3rd should fail
            await this.creditProtocol.issueDebt( ucacId1, p1, p2, amount
                                           , sig1.r, sig1.s, sig1.v
                                           , sig2.r, sig2.s, sig2.v, {from: p1}).should.be.rejectedWith(h.EVMThrow);
            debtCreated = await this.creditProtocol.balances(ucacId1, p1);
            debtCreated.should.be.bignumber.equal(web3.toBigNumber(amount).mul(2));
            debtCreated2 = await this.creditProtocol.balances(ucacId1, p2);
            debtCreated2.should.be.bignumber.equal(web3.toBigNumber(amount).mul(2).neg());
        });
    });

});
