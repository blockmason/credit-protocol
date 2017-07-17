var FriendInDebt = artifacts.require("./FriendInDebt.sol");
var Friendships  = artifacts.require("./Friendships.sol");

module.exports = function(deployer) {
    deployer.deploy(Friendships, "0x38d9c595d3da9d5023ed01a29f19789bf02187ef");
//    deployer.deploy(FriendInDebt, "0x0", "0x0");
//  deployer.link(ConvertLib, MetaCoin);
//  deployer.deploy(MetaCoin);
};
