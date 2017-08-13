pragma solidity ^0.4.11;

contract AbstractFriendReader {
  function numFriends(bytes32 fId) constant returns (uint);
  function friendIdByIndex(bytes32 fId, uint index) returns (bytes32);
  function areFriends(bytes32 _id1, bytes32 _id2) constant returns (bool);
}
