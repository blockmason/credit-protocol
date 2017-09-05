pragma solidity ^0.4.13;

contract AbstractStakeData {
  function getUcacAddr(bytes32 ucacId) public constant returns (address);
}
