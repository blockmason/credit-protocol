pragma solidity ^0.4.11;

contract AbstractHarmony {
  function isHarmonized(address _caller, bytes32 _name) constant returns (bool);
  function resolveToName(address _caller) constant returns (bytes32);
  function idEq(bytes32 _id1, bytes32 id2) constant returns (bool);
}
