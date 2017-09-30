var h = require("./helpers/helpers");

const should = require('chai')
          .use(require('chai-as-promised'))
          .use(require('chai-bignumber')(h.BigNumber))
          .should();

const FriendData = artifacts.require('./FriendData.sol');

contract('FriendData', function([admin1, admin2, p1, p2]) {
    before(async function() {
        // Advance to the next block to correctly read time in the solidity
        // "now" function interpreted by testrpc
    });

    beforeEach(async function() {
        this.frienddebt = await FriendData.new({from: admin1});
    });
});
