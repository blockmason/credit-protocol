var FriendInDebt = artifacts.require("./FriendInDebt.sol");

assertThrow = function(error, throwChecker) {
    if(error.toString().indexOf("invalid opcode") != -1) {
        throwChecker.gotThrow = true;
    } else {
        // if the error is something else (e.g., the assert from previous promise), then we fail the test
        assert(false, "Other error: " + error.toString());
    }
};

contract('FriendInDebt', function(accounts) {
    var account1 = accounts[0];
    var account2 = accounts[1];
    var account3 = accounts[2];

    it("should create a friendship and prevent operations with checkMutual() until both sides confirm", function() {
        var fid;
        var throwChecker = { "gotThrow": false };
        return FriendInDebt.new().then(function(instance) {
            fid = instance;
            return fid.createFriendship(account2, {from: account1});
        }).then(function(tx) {
            return fid.createFriendship(account1, {from: account2});
        }).then(function(tx) {
            return fid.createFriendship(account3, {from: account2});
        }).then(function(tx) {
            return fid.getFriends.call(account1);
        }).then(function(friendListPersonOne) {
            assert.equal(friendListPersonOne.valueOf()[0], account2, "wrong friends personOne");
            return fid.getFriends.call(account2);
        }).then(function(friendListPersonTwo) {
            assert.equal(friendListPersonTwo.valueOf()[0], account1, "wrong friends personTwo");
            assert.equal(friendListPersonTwo.valueOf()[1], account3, "wrong friends personTwo");
            return fid.newPending(account3, 10, {from: account2});
        }).then(function(tx) {
            assert.equal(true, false, "account2 can't make pending for account3--not mutual friends");
        }).catch(function(error) {
            assertThrow(error, throwChecker);
        });
    });

    it("should create pending debt; cancel any amount; confirm correct amount", function() {
        var fid;
        var throwChecker = { "gotThrow": false };
        var deposit1 = 20;
        var deposit2 = 30;
        var deposit3 = 70;
        return FriendInDebt.new().then(function(instance) {
            fid = instance;
            return fid.createFriendship(account2, {from: account1});
        }).then(function(tx) {
            return fid.createFriendship(account1, {from: account2});
        }).then(function(tx) {
            //account1 owes $20 to account2
            return fid.newPending(account1, deposit1, {from: account2});
        }).then(function(tx) {
            return fid.cancelPending(account2, {from: account1});
        }).then(function(tx) {
            return fid.newPending(account1, deposit2, {from: account2});
        }).then(function(tx) {
            return fid.newPending(account1, deposit3, {from: account2});
        }).then(function(tx) {
            return fid.confirmPending(account2, deposit2 + deposit3);
        }).then(function(tx) {
            return fid.getBalance.call(account1, account2);
        }).then(function(val) {
            assert.equal(val.toNumber(), deposit2 + deposit3, "account1 doesn't owe right amount to account2");
            return fid.getBalance.call(account2, account1);
        }).then(function(val) {
            assert.equal(val.toNumber(), (-1) * (deposit2 + deposit3), "account2 doesn't owe right amount to account1");
        });
    });

    it("shouldn't be able to confirm a debt that doesn't match the pending amount", function() {
        var fid;
        var throwChecker = { "gotThrow": false };
        var deposit1 = 20;
        var otherAmount = 30;
        return FriendInDebt.new().then(function(instance) {
            fid = instance;
            return fid.createFriendship(account2, {from: account1});
        }).then(function(tx) {
            return fid.createFriendship(account1, {from: account2});
        }).then(function(tx) {
            //account1 owes $20 to account2
            return fid.newPending(account1, deposit1, {from: account2});
        }).then(function(tx) {
            return fid.confirmPending(account2, otherAmount, {from: account1});
        }).then(function(tx) {
            assert.equal(true, false, "shouldn't confirmPending with non-matching amounts");
        }).catch(function(error) {
            assertThrow(error, throwChecker);
        });
    });
});
