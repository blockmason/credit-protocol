pragma solidity ^0.4.11;

import "./AbstractFoundation.sol";

contract Friendships {
  AbstractFoundation af;

  struct Friendship {
    bool initialized;
    bytes32 f1Id;
    bytes32 f2Id;
    bool isPending;
    bool isMutual;
    bool f1Confirmed;
    bool f2Confirmed;
  }

  mapping ( bytes32 => bytes32[] ) friendIdList;
  mapping ( bytes32 => mapping ( bytes32 => Friendship )) friendships;

  function Friendships(address foundationContract) {
    af  = AbstractFoundation(foundationContract);
  }

  modifier isIdOwner(address _caller, bytes32 _name) {
    if ( ! af.isUnified(_caller, _name) ) revert();
    _;
  }

  function areFriends(bytes32 _id1, bytes32 _id2) constant returns (bool) {
    return friendships[_id1][_id2].isMutual;
  }

  function addFriend(bytes32 myId, bytes32 friendId) isIdOwner(msg.sender, myId) {
    Friendship memory fs = friendships[myId][friendId];
    //if not initialized, create the Friendship
    if ( !fs.initialized ) {
      fs.initialized = true;
      fs.f1Id = myId;
      fs.f2Id = friendId;
      fs.isPending = true;
      fs.f1Confirmed = true;

      friendIdList[myId].push(friendId);
      friendIdList[friendId].push(myId);

      friendships[myId][friendId] = fs;
      friendships[friendId][myId] = fs;
      return;
    }
    if ( fs.isMutual ) return;

    if ( af.idEq(fs.f1Id, myId) ) fs.f1Confirmed = true;
    if ( af.idEq(fs.f2Id, myId) ) fs.f2Confirmed = true;

    //if friend has confirmed already, friendship is mutual
    if ( ( af.idEq(fs.f1Id, friendId) && fs.f1Confirmed)
         ||
         ( af.idEq(fs.f2Id, friendId) && fs.f2Confirmed) ) {
      fs.isMutual = true;
      fs.isPending = false;

      friendships[myId][friendId] = fs;
      friendships[friendId][myId] = fs;
      return;
    }
    //if friend hasn't confirmed, make this pending
    else {
      fs.isPending = true;

      friendships[myId][friendId] = fs;
      friendships[friendId][myId] = fs;
    }
  }

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
}
