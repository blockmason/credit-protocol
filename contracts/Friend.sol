pragma solidity ^0.4.11;

import "./AbstractFoundation.sol";
import "./AbstractFIDData.sol";

contract Friend {
  AbstractFIDData afd;
  AbstractFoundation af;

  function Friend(address dataContract, address foundationContract) {
    afd = AbstractFIDData(dataContract);
    af  = AbstractFoundation(foundationContract);
  }

  modifier isIdOwner(address _caller, bytes32 _name) {
    if ( ! af.isUnified(_caller, _name) ) revert();
    _;
  }

  function areFriends(bytes32 _id1, bytes32 _id2) constant returns (bool) {
    return afd.fIsMutual(_id1, _id2);
  }

  function addFriend(bytes32 myId, bytes32 friendId) isIdOwner(msg.sender, myId) {
    //if not initialized, create the Friendship
    if ( !afd.fInitialized(myId, friendId) ) {
      afd.fSetInitialized(myId, friendId, true);
      afd.fSetf1Id(myId, friendId, myId);
      afd.fSetf2Id(myId, friendId, friendId);
      afd.fSetIsPending(myId, friendId, true);
      afd.fSetf1Confirmed(myId, friendId, true);

      afd.fSetInitialized(friendId, myId, true);
      afd.fSetf1Id(friendId, myId, myId);
      afd.fSetf2Id(friendId, myId, friendId);
      afd.fSetIsPending(friendId, myId, true);
      afd.fSetf1Confirmed(friendId, myId, true);

      afd.pushFriendId(myId, friendId);
      afd.pushFriendId(friendId, myId);
      return;
    }
    if ( afd.fIsMutual(myId, friendId) ) return;

    if ( af.idEq(afd.ff1Id(myId, friendId), myId) ) {
      afd.fSetf1Confirmed(myId, friendId, true);
      afd.fSetf1Confirmed(friendId, myId, true);
    }
    if ( af.idEq(afd.ff2Id(myId, friendId), myId) ) {
      afd.fSetf2Confirmed(myId, friendId, true);
      afd.fSetf2Confirmed(friendId, myId, true);
    }

    //if friend has confirmed already, friendship is mutual
    if (
        ( af.idEq(afd.ff1Id(myId, friendId), friendId) && afd.ff1Confirmed(myId, friendId))
        ||
        ( af.idEq(afd.ff2Id(myId, friendId), friendId) && afd.ff2Confirmed(myId, friendId))) {
      afd.fSetIsMutual(myId, friendId, true);
      afd.fSetIsPending(myId, friendId, false);

      afd.fSetIsMutual(friendId, myId, true);
      afd.fSetIsPending(friendId, myId, false);
      return;
    }
    //if friend hasn't confirmed, make this pending
    else {
      afd.fSetIsPending(myId, friendId, true);
      afd.fSetIsPending(friendId, myId, true);
    }
  }

  function deleteFriend(bytes32 myId, bytes32 friendId) isIdOwner(msg.sender, myId) {
    afd.fSetInitialized(myId, friendId, false);
    afd.fSetInitialized(friendId, myId, false);

    afd.fSetIsMutual(myId, friendId, false);
    afd.fSetIsMutual(friendId, myId, false);

    afd.fSetIsPending(myId, friendId, false);
    afd.fSetIsPending(friendId, myId, false);
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
      //      Friendship memory fs = friendships[fId][currFriendId];
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
