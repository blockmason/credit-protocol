pragma solidity ^0.4.11;

contract StakeData {

  struct Ucac {
    bytes32 id;
    address ucacAddr;
    bytes32 ownerId;
  }

  mapping (bytes32 => Ucac) ucacs; //indexed by ucacId
}


/*
Staking notes:
Ucacs are indexed by ucacId
contain
- ucacId (bytes32)
- ucacAddr (contract address; can be changed)
- ownerId (foundationId)
*/
