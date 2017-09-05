pragma solidity ^0.4.13;

contract StakeData {
  address stakeContract;

  struct Ucac {
    bytes32 id;
    address ucacAddr;
    bytes32 ownerId;
  }

  mapping (bytes32 => Ucac) ucacs; //indexed by ucacId

  function StakeData() {

  }

  function setStakeContract() public isAdmin {

  }

  function getUcacAddr(bytes32 ucacId) public constant returns (address) {
    return ucacs[ucacId].ucacAddr;
  }

  function setUcacAddr(bytes32 _ucacId, address _ucacAddr) public isParent {

  }
}


/*
Staking notes:
Ucacs are indexed by ucacId
contain
- ucacId (bytes32)
- ucacAddr (contract address; can be changed)
- ownerId (foundationId)
*/
