pragma solidity ^0.4.11;

import "./AbstractFoundation.sol";

contract FriendInDebtNS {
  mapping ( bytes32 => string ) userNames;  //user address to a name
  AbstractFoundation af;

  modifier isIdOwner(address _caller, bytes32 _name) {
    if ( ! af.isUnified(_caller, _name) ) revert();
    _;
  }

  function FriendInDebtNS(address foundationContract) {
    af = AbstractFoundation(foundationContract);
  }

  function setName(string _name, bytes32 foundationId) isIdOwner(msg.sender, foundationId) {
    userNames[foundationId] = _name;
  }

  function getName(bytes32 _foundationId) constant returns (string) {
    return userNames[_foundationId];
  }
}
