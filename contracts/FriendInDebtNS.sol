pragma solidity ^0.4.11;

contract FriendInDebtNS {
  mapping ( address => string ) users;  //user address to a name

  function FriendInDebtNS() {

  }

  function setName(string _name) {
    users[msg.sender] = _name;
  }

  function getName(address _user) constant returns (string){
    return users[_user];
  }
}
