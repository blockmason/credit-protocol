var DebtData = artifacts.require("./DebtData.sol");
var FriendData = artifacts.require("./FriendData.sol");
var DebtReader = artifacts.require("./DebtReader.sol");
var FriendReader = artifacts.require("./FriendReader.sol");
var Flux = artifacts.require("./Flux.sol");
var Fid = artifacts.require("./Fid.sol");

//Note: replace this with Foundation's address when new one deployed on testrpc
var foundation = "0xdd1c6c4fff2efd226f5f4df60b6ae5848b7973d6";
var adminId = "timgalebach";
var user2 = "timg";
var user3 = "jaredb";
var user4 = "lukez";
var currency = "USD";
var ddata;
var fdata;
var dread;
var fread;
var flux;
var fid;
var d;
var f;
var instance;

contract('FriendInDebt', function(accounts) {
    var account1 = accounts[0];
    var account2 = accounts[1];
    var account3 = accounts[2];
    var account4 = accounts[3];

    var friends;
    it("add a friend, have pending, confirm friend, no more pending", async function() {
        var ddata = await DebtData.new(account2, {from: account1});
        var fdata = await FriendData.new(account2, {from: account1});
        var fread = await FriendReader.new(fdata.address, {from: account1});
        var dread = await DebtReader.new(ddata.address, fread.address, foundation, {from: account1});
        var flux  = await Flux.new(adminId, ddata.address, fdata.address, fread.address, foundation, {from: account1});
        var fid   = await Fid.new(adminId, foundation, ddata.address, fdata.address, {from: account1});
        return DebtData.deployed().then(function(debtInstance) {
            d = debtInstance;
            return d.setFluxContract(flux.address, {from: account1});
        }).then(function(tx) {
            return fdata.setFluxContract(flux.address, {from: account1});
        }).then(function(tx) {
            return flux.addFriend(fid.address, user2, user3, {from: account2});
        }).then(function(tx) {
            return fread.pendingFriends(fid.address, user3);
        }).then(function(v) {
            friends = pendingFriends2Js(v.valueOf());
            assert.equal(friends[0].friendId, user2, "user2 not in the pending list");
            assert.equal(friends[0].confirmerId, user3, "user3 not in the ids to confirm list");
            return fread.pendingFriends(fid.address, user2);
        }).then(function(v) {
            friends = pendingFriends2Js(v.valueOf());
            assert.equal(friends[0].friendId, user3, "user3 not in the pending list");
            assert.equal(friends[0].confirmerId, user3, "user3 not in the ids to confirm list");
            return fread.confirmedFriends(fid.address, user2);
        }).then(function(v) {
            friends = confirmedFriends2Js(v.valueOf());
            assert.equal(friends.length, 0, "should not have confirmed friends");
            return fread.confirmedFriends(fid.address, user3);
        }).then(function(v) {
            friends = confirmedFriends2Js(v.valueOf());
            assert.equal(friends.length, 0, "should not have confirmed friends");
            return flux.addFriend(fid.address, user3, user2, {from: account3});
        }).then(function(v) {
            return fread.pendingFriends(fid.address, user2);
        }).then(function(v) {
            friends = pendingFriends2Js(v.valueOf());
            assert.equal(friends.length, 0, "user2 should not have pending friends");
            return fread.pendingFriends(fid.address, user3);
        }).then(function(v) {
            friends = pendingFriends2Js(v.valueOf());
            assert.equal(friends.length, 0, "user3 should not have pending friends");
            return fread.confirmedFriends(fid.address, user3);
        }).then(function(v) {
            friends = confirmedFriends2Js(v.valueOf());
            assert.equal(friends[0].friendId, user2, "user3 should have confirmed friends");
            return fread.confirmedFriends(fid.address, user2);
        }).then(function(v) {
            friends = confirmedFriends2Js(v.valueOf());
            assert.equal(friends[0].friendId, user3, "user2 should have confirmed friends");
        });
    });
    /*
    it("correct number of confirmed debt balances", async function() {
        var amt1 = 2000;
        var amt2 = 3000;
        var amt3 = 8000;
        var desc1 = "stuff you bought";
        var desc2 = "bad things I owe for";
        var desc3 = "hookers and blow";
        var debts;

        dbdata = await DPData.new(account2, {from: account1});
        f = await Friend.new(dpdata.address, foundation, {from: account1});
        return FluxxxyDP.new(adminId, dpdata.address, f.address, foundation, {from: account1}).then(function(debtInstance) {
            d = debtInstance;
            return dpdata.setFriendContract(f.address, {from: account1});
        }).then(function(tx) {
            return dpdata.setFluxContract(d.address, {from: account1});
        }).then(function(tx) {
            return d.addCurrencyCode(currency, {from: account1});
        }).then(function(v) {
            return f.addFriend(user2, user3, {from: account2});
        }).then(function(v) {
            return f.addFriend(user3, user2, {from: account3});
        }).then(function(v) {
            return f.addFriend(user2, user4, {from: account2});
        }).then(function(v) {
            return f.addFriend(user4, user2, {from: account4});
        }).then(function(v) {
            return d.newDebt(d.address, user2, user3, currency, amt1, desc1, {from: account2});
        }).then(function(v) {
            return d.newDebt(d.address, user3, user2, currency, amt2, desc2, {from: account2});
        }).then(function(v) {
            return d.newDebt(d.address, user3, user2, currency, amt3, desc3, {from: account3});
        }).then(function(v) {
            return d.newDebt(d.address, user2, user4, currency, amt1, desc3, {from: account2});
        }).then(function(v) {
            return d.newDebt(d.address, user2, user4, currency, amt2, desc3, {from: account2});
        }).then(function(v) {
            return d.newDebt(d.address, user2, user4, currency, amt3, desc3, {from: account2});
        }).then(function(v) {
            return d.rejectDebt(user3, user2, 1, {from: account3});
        }).then(function(v) {
            return d.confirmDebt(user3, user2, 0, {from: account3});
        }).then(function(v) {
            return d.confirmDebt(user2, user3, 2, {from: account2});
        }).then(function(v) {
            return d.confirmDebt(user4, user2, 3, {from: account4});
        }).then(function(v) {
            return d.confirmDebt(user4, user2, 4, {from: account4});
        }).then(function(v) {
            return d.confirmDebt(user4, user2, 5, {from: account4});
        }).then(function(v) {
            return d.confirmedDebtBalances.call(user2);
        }).then(function(v) {
            debts = debtBalances2Js(v.valueOf());
            assert.equal(debts.length, 2, "should have 2 confirmed debt balances");
            assert.equal(debts[0].totalDebts, 2, "should have 2 confirmed debts with user3");
            assert.equal(debts[1].totalDebts, 3, "should have 3 confirmed debts with user4");
        });
    });
*/

    /*
    it("create debt; check,confirm it; create debt; check,reject it", async function() {
        var amt1 = 2000;
        var amt2 = 3000;
        var amt3 = 8000;
        var desc1 = "stuff you bought";
        var desc2 = "bad things I owe for";
        var desc3 = "hookers and blow";

        var debts;

        dbdata = await DPData.new(account2, {from: account1});
        f = await Friend.new(dpdata.address, foundation, {from: account1});
        return FluxxxyDP.new(adminId, dpdata.address, f.address, foundation, {from: account1}).then(function(debtInstance) {
            d = debtInstance;
            return dpdata.setFriendContract(f.address, {from: account1});
        }).then(function(tx) {
            return dpdata.setFluxContract(d.address, {from: account1});
        }).then(function(tx) {
            return d.addCurrencyCode(currency, {from: account1});
        }).then(function(v) {
            return f.addFriend(user2, user3, {from: account2});
        }).then(function(v) {
            return f.addFriend(user3, user2, {from: account3});
        }).then(function(v) {
            return d.newDebt(d.address, user2, user3, currency, amt1, desc1, {from: account2});
        }).then(function(v) {
            return d.newDebt(d.address, user3, user2, currency, amt2, desc2, {from: account2});
        }).then(function(v) {
            return d.newDebt(d.address, user3, user2, currency, amt3, desc3, {from: account3});
        }).then(function(v) {
            return d.pendingDebts(user2, user3);
        }).then(function(v) {
            debts = pendingDebts2Js(v.valueOf());
            assert.equal(debts[0].id, 0, "1st pending id not 0");
            assert.equal(debts[1].id, 1, "2nd pending id not 1");
            assert.equal(debts[0].confirmerId, user3, "user3 should be on the hook to confirm first debt");
            assert.equal(debts[0].creditor, user3, "1st debt creditor should be user3");
            assert.equal(debts[0].debtor, user2, "1st debt debtor should be user2");
            assert.equal(debts[1].creditor, user2, "2nd debt creditor should be user2");
            assert.equal(debts[1].debtor, user3, "2nd debt debtor should be user3");
            return d.confirmDebt(user3, user2, debts[0].id, {from: account3});
        }).then(function(v) {
            return d.pendingDebts(user3, user2);
        }).then(function(v) {
            return d.pendingDebts(user2, user3);
        }).then(function(v) {
            debts = pendingDebts2Js(v.valueOf());
            assert.equal(debts.length, 2, "Should have 2 pending debts left");
            return d.rejectDebt(user3, user2, debts[0].id, {from: account3}); //reject
        }).then(function(v) {
            return d.pendingDebts(user2, user3);
        }).then(function(v) {
            debts = pendingDebts2Js(v.valueOf());
            assert.equal(debts.length, 1, "user2 should have 1 pending debt");
            return d.confirmedDebts(user2, user3);
        }).then(function(v) {
            debts = confirmedDebts2Js(v.valueOf());
            assert.equal(debts.length, 1, "user2 should have 1 confirmed debt");
            assert.equal(debts[0].amount, amt1, "amount should be " + amt1);
            return d.pendingDebts(user2, user3);
        }).then(function(v) {
            debts = pendingDebts2Js(v.valueOf());
            return d.confirmDebt(user2, user3, debts[0].id, {from: account2});
        }).then(function(v) {
            return d.confirmedDebtBalances(user2);
        }).then(function(v) {
            debts = debtBalances2Js(v.valueOf());
            assert.equal(debts[0].amount, -6000, "user2 should be owed 6000 from user3");
            return d.confirmedDebtBalances(user3);
        }).then(function(v) {
            debts = debtBalances2Js(v.valueOf());
            assert.equal(debts[0].amount, 6000, "user3 should owe 6000 to user2");
        });
    });
*/

});


var confirmedFriends2Js = function(friends) {
    var friendList = [];
    for ( var i=0; i < friends.length; i++ ) {
        var friend = {
            friendId: b2s(friends[i])
        };
        friendList.push(friend);
    }
    return friendList;
};

var pendingFriends2Js = function(friends) {
    var friendList = [];
    for ( var i=0; i < friends[0].length; i++ ) {
        var friend = {
            friendId: b2s(friends[0][i]),
            confirmerId: b2s(friends[1][i])
        };
        friendList.push(friend);
    }
    return friendList;
};

var pendingDebts2Js = function(debts) {
    var debtList = [];
    //debts[0] is all the debtIds, debts[1] is confirmerIds, etc
    for ( var i=0; i < debts[0].length; i++ ) {
        var debt = { id: debts[0][i].toNumber(),
                     confirmerId: b2s(debts[1][i]),
                     currency: b2s(debts[2][i]),
                     amount: debts[3][i].toNumber(),
                     desc: b2s(debts[4][i]),
                     debtor: b2s(debts[5][i]),
                     creditor: b2s(debts[6][i])  };
        debtList.push(debt);
    }
    return debtList;
};

var confirmedDebts2Js = function(debts) {
    var debtList = [];
    for ( var i=0; i < debts[0].length; i++ ) {
        var debt = { currency: b2s(debts[0][i]),
                     amount: debts[1][i].toNumber(),
                     desc: b2s(debts[2][i]),
                     debtor: b2s(debts[3][i]),
                     creditor: b2s(debts[4][i]),
                     timestamp: debts[5][i].toNumber() };
        debtList.push(debt);
    }
    return debtList;
};

var debtBalances2Js = function(debts) {
    var balanceList = [];
    for ( var i=0; i < debts[0].length; i++ ) {
        var debt = { currency: b2s(debts[0][i]),
                     amount: debts[1][i].toNumber(),
                     counterParty: b2s(debts[2][i]),
                     totalDebts: debts[3][i].toNumber(),
                     mostRecent: debts[4][i].toNumber() };
        balanceList.push(debt);
    }
    return balanceList;
};

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
