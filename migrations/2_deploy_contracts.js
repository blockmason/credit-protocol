var FIDData = artifacts.require("./FIDData.sol");
var Debt = artifacts.require("./Debt.sol");
var Friend  = artifacts.require("./Friend.sol");
var foundationContract = "0x1c860055766844320466e66b41891e4814b7c089";

var instance;

module.exports = function(deployer, network, accounts) {
    if ( network == "testrpc" ) {
        var admin = "timgalebach";
        var user2 = "timg"; //also admin2
        var user3 = "jaredb";
        var account2 = accounts[1];
        var account3 = accounts[2];

        deployer.deploy(FIDData, account2, {from: accounts[0]}).then(function() {
            return deployer.deploy(Friend, FIDData.address, foundationContract, {from: accounts[0]});
        }).then(function() {
            return deployer.deploy(Debt, admin, FIDData.address, Friend.address, foundationContract, {from: accounts[0]});
        });
        deployer.then(function() {
            return FIDData.deployed();
        }).then(function(fdata) {
            instance = fdata;
            return instance.setFriendContract(Friend.address, {from: accounts[0]});
        }).then(function(tx) {
            return instance.setDebtContract(Debt.address, {from: accounts[0]});
        }).then(function(tx) {
            return Friend.deployed();
        }).then(function(f) {
            instance = f;
            return instance.addFriend(user2, user3, {from: account2});
        }).then(function(tx) {
            return instance.addFriend(user3, user2, {from: account3});
        });
    }

};
