pragma solidity ^0.4.11;

contract AbstractFriendReader {
  function numFriends(address ucac, bytes32 fId) constant returns (uint);
  function friendIdByIndex(address ucac, bytes32 fId, uint index) returns (bytes32);
  function areFriends(address ucac, bytes32 _id1, bytes32 _id2) constant returns (bool);
  function confirmedFriends(address ucac, bytes32 fId) constant returns (bytes32[] confirmedFriends);
  function pendingFriends(address ucac, bytes32 fId) constant returns (bytes32[] friendIds, bytes32[] confirmerIds);
}
