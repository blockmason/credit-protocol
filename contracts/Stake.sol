pragma solidity ^0.4.11;

contract Stake {
  bytes32 admin;

  mapping ( address => address[] ) ucacIdToUcac;

  function Stake(bytes32 _admin) {
    admin = _admin;
  }

  function isValidUcac(address ucacId, address ucac) {
    return isMember(ucac, ucacIdToUcac[ucacId]);
  }

  function isMember(address a, address[] l) constant returns(bool) {
    for ( uint i=0; i < l.length; i++ ) {
      if ( a == l[i] ) return true;
    }
    return false;
  }
}
