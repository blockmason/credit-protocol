var FriendInDebt = artifacts.require("./FriendInDebt.sol");

var harmony = "0x4c553e1e284472acda8acbc06ed88fcf16947a88";
var adminId = "harmonyadmin";
var user2 = "timg";
var user3 = "jaredb";

var b2s = function(bytes) {
    var s = "";
    for(var i=2; i<bytes.length; i+=2) {
        var num = parseInt(bytes.substring(i, i+2), 16);
        if (num == 0) break;
        var char = String.fromCharCode(num);
        s += char;
    }
    return s;
};

contract('FriendInDebt', function(accounts) {
    var account1 = accounts[0];
    var account2 = accounts[1];
    var account3 = accounts[2];

    it("add a friend, have pending, confirm friend, no more pending", function() {
        var fid;
        return FriendInDebt.new(adminId, harmony).then(function(instance) {
            fid = instance;
            return fid.addFriend(user2, user3, {from: account2});
        }).then(function(v) {
            return fid.pendingFriends(user3);
        }).then(function(v) {
            assert.equal(b2s(v.valueOf()[0][0]), user2, "user2 not in the pending list");
            assert.equal(b2s(v.valueOf()[1][0]), user3, "user3 not in the ids to confirm list");
            return fid.pendingFriends(user2);
        }).then(function(v) {
            assert.equal(b2s(v.valueOf()[0][0]), user3, "user3 not in the pending list");
            assert.equal(b2s(v.valueOf()[1][0]), user3, "user3 not in the ids to confirm list");

            return fid.confirmedFriends(user2);
        }).then(function(v) {
            assert.equal(v.valueOf().length, 0, "should not have confirmed friends");
            return fid.confirmedFriends(user3);
        }).then(function(v) {
            assert.equal(v.valueOf().length, 0, "should not have confirmed friends");
            return fid.addFriend(user3, user2, {from: account3});
        }).then(function(v) {
            return fid.pendingFriends(user2);
        }).then(function(v) {
            assert.equal(v.valueOf()[0].length, 0, "user2 should not have pending friends");
            return fid.pendingFriends(user3);
        }).then(function(v) {
            assert.equal(v.valueOf()[0].length, 0, "user3 should not have pending friends");
            return fid.confirmedFriends(user3);
        }).then(function(v) {
            assert.equal(b2s(v.valueOf()[0]), user2, "user3 has no confirmed friends");
            return fid.confirmedFriends(user2);
        }).then(function(v) {
            assert.equal(b2s(v.valueOf()[0]), user3, "user2 has no confirmed friends");
        });
    });

    it("create debt; check,confirm it; create debt; check,reject it", function() {
        var fid;
        var currency = "EURcents";
        var posAmt = 2000;
        var negAmt = -3000;
        var desc1 = "butt stuff";
        var desc2 = "bad thigns";

        var x;
        return FriendInDebt.new(adminId, harmony).then(function(instance) {
            fid = instance;
            return fid.addFriend(user2, user3, {from: account2});
        }).then(function(v) {
            return fid.addFriend(user3, user2, {from: account3});
        }).then(function(v) {
            return fid.newDebt(user2, user3, currency, posAmt, desc1, {from: account2});
        }).then(function(v) {
            return fid.newDebt(user2, user3, currency, negAmt, desc2, {from: account2});
        }).then(function(v) {
            return fid.pendingDebts(user2, user3);
        }).then(function(v) {
            x = v.valueOf();
            assert.equal(x[0][0], 0, "1st pending id not 0");
            assert.equal(x[0][1], 1, "2nd pending id not 1");
            assert.equal(b2s(x[1][0]), user3, "user3 should be on the hook to confirm first debt");
            assert.equal(b2s(x[6][0]), user3, "1st debt creditor should be user3");
            assert.equal(b2s(x[5][0]), user2, "1st debt debtor should be user2");
            assert.equal(b2s(x[6][1]), user2, "2nd debt creditor should be user2");
            assert.equal(b2s(x[5][1]), user3, "2nd debt debtor should be user3");

            return fid.confirmDebt(user3, user2, x[0][0], {from: account3});
        }).then(function(v) {
            return fid.pendingDebts(user2, user3);
        }).then(function(v) {
            x = v.valueOf();
            assert.equal(x[0].length, 1, "Should only have one pending debt left");
            //            return fid.rejectDebt(user3, user2, x[0][0]);
        }).then(function(v) {
            console.log(v);
        });
    });
});
