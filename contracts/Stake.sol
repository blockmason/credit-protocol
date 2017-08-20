pragma solidity ^0.4.11;

contract Stake {
  bytes32 admin;

  mapping ( address => address[] ) ucacIdToUcac;

  function State(bytes32 _admin) {
    admin = _admin;
  }
}
