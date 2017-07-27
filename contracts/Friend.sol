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
      afd.fSetIsPending(myId, friendId, true);
      afd.fSetIsMutual(friendId, myId, true);
      afd.fSetIsPending(friendId, myId, true);
      return;
    }
    //if friend hasn't confirmed, make this pending
    else {
      afd.fSetIsPending(myId, friendId, true);
      afd.fSetIsPending(friendId, myId, true);
    }
  }
    /*
  function deleteFriend(bytes32 myId, bytes32 friendId) isIdOwner(msg.sender, myId) {
    friendships[myId][friendId].initialized = false;
    friendships[friendId][myId].initialized = false;

    friendships[myId][friendId].isMutual = false;
    friendships[friendId][myId].isMutual = false;

    friendships[myId][friendId].isPending = false;
    friendships[friendId][myId].isPending = false;
  }

  function numFriends(bytes32 _foundationId) constant returns (uint) {
    return friendIdList[_foundationId].length;
  }

  function friendIdByIndex(bytes32 _foundationId, uint index) returns (bytes32) {
    return friendIdList[_foundationId][index];
  }

  bytes32[] cFriends; //"local" variable for fn
  function confirmedFriends(bytes32 _foundationId) constant returns (bytes32[]) {
    cFriends.length = 0;
    for ( uint i=0; i<friendIdList[_foundationId].length; i++ ) {
      bytes32 currFriendId = friendIdList[_foundationId][i];
      if ( friendships[_foundationId][currFriendId].isMutual )
        cFriends.push(currFriendId);
    }
    return cFriends;
  }

  bytes32[] pFriends; //"local" variable for fn
  bytes32[] idsNeededToConfirmF;
  function pendingFriends(bytes32 _foundationId) constant returns (bytes32[] friendIds, bytes32[] confirmerIds) {
    pFriends.length = 0;
    for ( uint i=0; i<friendIdList[_foundationId].length; i++ ) {
      bytes32 currFriendId = friendIdList[_foundationId][i];
      Friendship memory fs = friendships[_foundationId][currFriendId];
      if ( fs.isPending ) {
        pFriends.push(currFriendId);
        if ( fs.f1Confirmed )
          idsNeededToConfirmF.push(fs.f2Id);
        else
          idsNeededToConfirmF.push(fs.f1Id);
      }
    }
    return (pFriends, idsNeededToConfirmF);
  }

    */

}
