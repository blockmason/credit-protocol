var FriendInDebt = artifacts.require("./FriendInDebt.sol");

module.exports = function(deployer) {
    deployer.deploy(FriendInDebt, "0x0");
//  deployer.link(ConvertLib, MetaCoin);
//  deployer.deploy(MetaCoin);
};
