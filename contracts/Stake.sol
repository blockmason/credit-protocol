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
  }

}
