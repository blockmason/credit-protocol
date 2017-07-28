var FIDData = artifacts.require("./FIDData.sol");
var Debt = artifacts.require("./Debt.sol");
var Friend  = artifacts.require("./Friend.sol");
var testFoundationContract = "0xad974f9245fac5a1029190c2875a401042ff6bcf";
var ropstenFoundationContract = "0x334c1e331ffca04b1aa902347994ddcb42e84858";

var oneGwei = 1000000000; //9 zeros
var fiveGwei = 5000000000; //9 zeros
var tenGwei = 10000000000; //10 zeros
var contractGasLimit = 4390000; //4.39M
var fnGasLimit = 1000000; //1.0M

var instance;
var admin = "timgalebach";
var metamaskAddr = "0x406Dd5315e6B63d6F1bAd0C4ab9Cd8EBA6Bb1bD2";
var currency = "USD";

module.exports = function(deployer, network, accounts) {
    if ( network == "testrpc" ) {
        var user2 = "timg"; //also admin2
        var user3 = "jaredb";
        var account2 = accounts[1];
        var account3 = accounts[2];

        deployer.deploy(FIDData, account2, {from: accounts[0]}).then(function() {
            return deployer.deploy(Friend, FIDData.address, testFoundationContract, {from: accounts[0]});
        }).then(function() {
            return deployer.deploy(Debt, admin, FIDData.address, Friend.address, testFoundationContract, {from: accounts[0]});
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

    if ( network == "ropsten" ) {
        var contractData =  {from: accounts[0],
                             gas: contractGasLimit,
                             gasPrice: fiveGwei};
        var fnData = {from: accounts[0],
                      gas: fnGasLimit,
                      gasPrice: fiveGwei};
        /*
        Debt.at("0xdc7a8b966fdcb9f73c1cf39d8327c32b34420271").then(function(d) {
            d.addCurrencyCode(currency, fnData);
        });
*/

        deployer.deploy(FIDData, metamaskAddr, contractData).then(function() {
            return deployer.deploy(Friend, FIDData.address, ropstenFoundationContract, contractData);
        }).then(function() {
            return deployer.deploy(Debt, admin, FIDData.address, Friend.address, ropstenFoundationContract, contractData);
        });
        deployer.then(function() {
            return FIDData.deployed();
        }).then(function(fdata) {
            instance = fdata;
            return instance.setFriendContract(Friend.address, fnData);
        }).then(function(tx) {
            return instance.setDebtContract(Debt.address, fnData);
            return Debt.deployed();
        }).then(function(d) {
            instance = d;
        }).then(function(tx) {
            return instance.addCurrencyCode(currency, fnData);
        });
    }

};
