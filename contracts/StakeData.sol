pragma solidity ^0.4.13;

contract StakeData {
  address stakeContract;
  address admin;
  address admin2;

  struct Ucac {
    bytes32 id;
    address ucacAddr;
    bytes32 ownerId;
  }

  /*  modifiers  */
  modifier isAdmin() {
    if ( (admin != msg.sender) && (admin2 != msg.sender)) revert();
    _;
  }

  modifier isParent() {
    if ( (msg.sender != stakeContract) ) revert();
    _;
  }

  mapping (bytes32 => Ucac) ucacs; //indexed by ucacId

  function StakeData(address _admin2) {
    admin = msg.sender;
    admin2 = _admin2;
  }

  function setStakeContract(address _stakeContract) public isAdmin {
    stakeContract = _stakeContract;
  }

  function getUcacAddr(bytes32 ucacId) public constant returns (address) {
    return ucacs[ucacId].ucacAddr;
  }

  function setUcacAddr(bytes32 _ucacId, address _ucacAddr) public isParent {

  }
}
