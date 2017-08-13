pragma solidity ^0.4.11;

import "./AbstractCPData.sol";

contract FriendReader {
  AbstractCPData acp;

  function FriendReader(address dataContract) {
    acp = AbstractCPData(dataContract);
  }

  function areFriends(bytes32 _id1, bytes32 _id2) constant returns (bool) {
    return acp.fIsMutual(_id1, _id2);
  }

  function numFriends(bytes32 fId) constant returns (uint) {
    return acp.numFriends(fId);
  }

  function friendIdByIndex(bytes32 fId, uint index) returns (bytes32) {
    return acp.friendIdByIndex(fId, index);
  }

  /*  Temporary variables */
  bytes32[] ids1;
  bytes32[] ids2;
  function confirmedFriends(bytes32 fId) constant returns (bytes32[] confirmedFriends) {
    ids1.length = 0;
    for ( uint i=0; i < acp.numFriends(fId); i++ ) {
      bytes32 currFriendId = friendIdByIndex(fId, i);
      if ( acp.fIsMutual(fId, currFriendId) )
        ids1.push(currFriendId);
    }
    return ids1;
  }

  function pendingFriends(bytes32 fId) constant returns (bytes32[] friendIds, bytes32[] confirmerIds) {
    ids1.length = 0;
    ids2.length = 0;
    for ( uint i=0; i < acp.numFriends(fId); i++ ) {
      bytes32 friendId = friendIdByIndex(fId, i);
      //      Friendship memory fs = friendships[fId][currFriendId];
      if ( acp.fIsPending(fId, friendId) ) {
        ids1.push(friendId);
        if ( acp.ff1Confirmed(fId, friendId) )
          ids2.push(acp.ff2Id(fId, friendId));
        else
          ids2.push(acp.ff1Id(fId, friendId));
      }
    }
    return (ids1, ids2);
  }
}
