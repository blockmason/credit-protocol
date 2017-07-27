pragma solidity ^0.4.11;

contract AbstractFriend {
  function areFriends(bytes32 _id1, bytes32 _id2) constant returns (bool);
  function numFriends(bytes32 _foundationId) constant returns (uint);
  function friendIdByIndex(bytes32 _foundationId, uint index) returns (bytes32);
}
