pragma solidity ^0.4.11;

import "./AbstractFriendData.sol";

contract FriendReader {
  AbstractFriendData afd;

  function FriendReader(address friendContract) {
    afd = AbstractFriendData(friendContract);
  }

  function areFriends(address ucac, bytes32 _id1, bytes32 _id2) constant returns (bool) {
    return afd.fIsMutual(ucac, _id1, _id2);
  }

  function numFriends(address ucac, bytes32 fId) constant returns (uint) {
    return afd.numFriends(ucac, fId);
  }

  function friendIdByIndex(address ucac, bytes32 fId, uint index) returns (bytes32) {
    return afd.friendIdByIndex(ucac, fId, index);
  }

  /*  Temporary variables */
  bytes32[] ids1;
  bytes32[] ids2;
  function confirmedFriends(address ucac, bytes32 fId) constant returns (bytes32[] confirmedFriends) {
    ids1.length = 0;
    for ( uint i=0; i < afd.numFriends(ucac, fId); i++ ) {
      bytes32 currFriendId = friendIdByIndex(ucac, fId, i);
      if ( afd.fIsMutual(ucac, fId, currFriendId) )
        ids1.push(currFriendId);
    }
    return ids1;
  }

  function pendingFriends(address ucac, bytes32 fId) constant returns (bytes32[] friendIds, bytes32[] confirmerIds) {
    ids1.length = 0;
    ids2.length = 0;
    for ( uint i=0; i < afd.numFriends(ucac, fId); i++ ) {
      bytes32 friendId = friendIdByIndex(ucac, fId, i);
      if ( afd.fIsPending(ucac, fId, friendId) ) {
        ids1.push(friendId);
        if ( afd.ff1Confirmed(ucac, fId, friendId) )
          ids2.push(afd.ff2Id(ucac, fId, friendId));
        else
          ids2.push(afd.ff1Id(ucac, fId, friendId));
      }
    }
    return (ids1, ids2);
  }
}
