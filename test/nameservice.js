var FriendInDebtNS = artifacts.require("./FriendInDebtNS.sol");

contract('FriendInDebtNS', function(accounts) {
    var account1 = accounts[0];
    var account2 = accounts[1];
    var account3 = accounts[2];

    var name1 = "Timothy Galebach";

    it("should set and retrieve a name; no name should be blank string", function() {
        var ns;
        return FriendInDebtNS.new().then(function(instance) {
            ns = instance;
            return ns.setName(name1, {from: account1});
        }).then(function(tx) {
            return ns.getName.call(account1);
        }).then(function(myName) {
            assert.equal(myName.valueOf(), name1, "wrong name retrieved");
            return ns.getName.call(account2);
        }).then(function(blankName) {
            assert.equal(blankName.valueOf(), "", "no name should yield blank");
        });
    });
});
