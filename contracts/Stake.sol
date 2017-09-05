pragma solidity ^0.4.13;

contract Stake {
  bytes32 admin;
  AbstractStakeData asd;

  mapping ( address => address[] ) ucacIdToUcac;

  function Stake(bytes32 _admin, address _stakeDataContract) {
    admin = _admin;
    asd = AbstractStakeData(_stakeDataContract);
  }

  function ucacAddress(bytes32 ucacId) constant returns (address) {
    return asd.getUcacAddr(ucacId);
  };

  function

  /*
  function isValidUcac(address ucacId, address ucac) {
    return isMember(ucac, ucacIdToUcac[ucacId]);
  }
  */

  function isMember(address a, address[] l) constant returns(bool) {
    for ( uint i=0; i < l.length; i++ ) {
      if ( a == l[i] ) return true;
    }
    return false;
  }
}
