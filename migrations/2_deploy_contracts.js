var testFoundationContract = "0x73a79e86cb10ba4495c42ccbd1de4d0c69008da4";

var DPData = artifacts.require("./DPData.sol");
var FluxxxyDP = artifacts.require("./FluxxxyDp.sol");
var Friend  = artifacts.require("./Friend.sol");

var ropstenFoundationContract = "0x3d38a834d911157cc1f1306273a9d790aa2b2c51";

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

        deployer.deploy(DPData, account2, {from: accounts[0]}).then(function() {
            return deployer.deploy(Friend, DPData.address, testFoundationContract, {from: accounts[0]});
        }).then(function() {
            return deployer.deploy(FluxxxyDP, admin, DPData.address, Friend.address, testFoundationContract, {from: accounts[0]});
        });

        deployer.then(function() {
            return DPData.deployed();
        }).then(function(dpdata) {
            instance = dpdata;
            return instance.setFriendContract(Friend.address, {from: accounts[0]});
        }).then(function(tx) {
            return instance.setFluxContract(FluxxxyDP.address, {from: accounts[0]});
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

        deployer.deploy(DPData, metamaskAddr, contractData).then(function() {
            return deployer.deploy(Friend, DPData.address, ropstenFoundationContract, contractData);
        }).then(function() {
            return deployer.deploy(FluxxxyDP, admin, DPData.address, Friend.address, ropstenFoundationContract, contractData);
        });
        deployer.then(function() {
            return DPData.deployed();
        }).then(function(fdata) {
            instance = fdata;
            return instance.setFriendContract(Friend.address, fnData);
        }).then(function(tx) {
            return instance.setFluxContract(FluxxxyDP.address, fnData);
        }).then(function(d) {
            return FluxxxyDP.deployed();
        }).then(function(d) {
            instance = d;
            return instance.addCurrencyCode(currency, fnData);
        });
    }

    if ( network == "ropstenNoData" ) {
        var contractData =  {from: accounts[0],
                             gas: contractGasLimit,
                             gasPrice: fiveGwei};
        var fnData = {from: accounts[0],
                      gas: fnGasLimit,
                      gasPrice: fiveGwei};

        var fdataContract = "0xc7debb9925d3e29f221c914a59961e728f6bd95a";

        deployer.deploy(Friend, fdataContract, ropstenFoundationContract, contractData).then(function() {
            return deployer.deploy(FluxxxyDP, admin, fdataContract, Friend.address, ropstenFoundationContract, contractData);
        });
        deployer.then(function() {
            return DPData.at(fdataContract);
        }).then(function(fdata) {
            instance = fdata;
            return instance.setFriendContract(Friend.address, fnData);
        }).then(function(tx) {
            return instance.setFluxContract(FluxxxyDP.address, fnData);
        }).then(function(d) {
            return FluxxxyDP.deployed();
        }).then(function(d) {
            instance = d;
            return instance.addCurrencyCode(currency, fnData);
        });
    }

};
