pragma solidity ^0.4.11;

import "./AbstractFriendData.sol";

contract FriendReader {
  AbstractFriendData afd;

  function FriendReader(address friendContract) {
    afd = AbstractFriendData(friendContract);
  }

  function areFriends(bytes32 _id1, bytes32 _id2) constant returns (bool) {
    return afd.fIsMutual(_id1, _id2);
  }

  function numFriends(bytes32 fId) constant returns (uint) {
    return afd.numFriends(fId);
  }

  function friendIdByIndex(bytes32 fId, uint index) returns (bytes32) {
    return afd.friendIdByIndex(fId, index);
  }

  /*  Temporary variables */
  bytes32[] ids1;
  bytes32[] ids2;
  function confirmedFriends(bytes32 fId) constant returns (bytes32[] confirmedFriends) {
    ids1.length = 0;
    for ( uint i=0; i < afd.numFriends(fId); i++ ) {
      bytes32 currFriendId = friendIdByIndex(fId, i);
      if ( afd.fIsMutual(fId, currFriendId) )
        ids1.push(currFriendId);
    }
    return ids1;
  }

  function pendingFriends(bytes32 fId) constant returns (bytes32[] friendIds, bytes32[] confirmerIds) {
    ids1.length = 0;
    ids2.length = 0;
    for ( uint i=0; i < afd.numFriends(fId); i++ ) {
      bytes32 friendId = friendIdByIndex(fId, i);
      if ( afd.fIsPending(fId, friendId) ) {
        ids1.push(friendId);
        if ( afd.ff1Confirmed(fId, friendId) )
          ids2.push(afd.ff2Id(fId, friendId));
        else
          ids2.push(afd.ff1Id(fId, friendId));
      }
    }
    return (ids1, ids2);
  }
}
