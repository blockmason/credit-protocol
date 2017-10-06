pragma solidity ^0.4.15;

import "./FriendData.sol";
import "blockmason-solidity-libs/contracts/Parentable.sol";
import "./AbstractFoundation.sol";

contract FriendInterface is Parentable {
  FriendData fd;
  AbstractFoundation af;

  function FriendInterface(address _friendDataContract, address _foundationContract) {
    fd = FriendData(_friendDataContract);
    af = AbstractFoundation(_foundationContract);
  }

  function areFriends(bytes32 ucacId, bytes32 _id1, bytes32 _id2) constant returns (bool) {
    return fd.fIsMutual(ucacId, _id1, _id2);
  }

  function numFriends(bytes32 ucacId, bytes32 fId) constant returns (uint) {
    return fd.numFriends(ucacId, fId);
  }

  function friendIdByIndex(bytes32 ucacId, bytes32 fId, uint index) returns (bytes32) {
    return fd.friendIdByIndex(ucacId, fId, index);
  }

  /*  Temporary variables */
  bytes32[] ids1;
  bytes32[] ids2;
  function confirmedFriends(bytes32 ucacId, bytes32 fId) constant returns (bytes32[]) {
    ids1.length = 0;
    for ( uint i=0; i < fd.numFriends(ucacId, fId); i++ ) {
      bytes32 currFriendId = friendIdByIndex(ucacId, fId, i);
      if ( fd.fIsMutual(ucacId, fId, currFriendId) )
        ids1.push(currFriendId);
    }
    return ids1;
  }

  function pendingFriends(bytes32 ucacId, bytes32 fId) constant returns (bytes32[] friendIds, bytes32[] confirmerIds) {
    ids1.length = 0;
    ids2.length = 0;
    for ( uint i=0; i < fd.numFriends(ucacId, fId); i++ ) {
      bytes32 friendId = friendIdByIndex(ucacId, fId, i);
      if ( fd.fIsPending(ucacId, fId, friendId) ) {
        ids1.push(friendId);
        if ( fd.ff1Confirmed(ucacId, fId, friendId) )
          ids2.push(fd.ff2Id(ucacId, fId, friendId));
        else
          ids2.push(fd.ff1Id(ucacId, fId, friendId));
      }
    }
    return (ids1, ids2);
  }

    /* Friend functions */
  function addFriend(bytes32 ucacId, bytes32 myId, bytes32 friendId) public onlyParent {
    //if not initialized, create the Friendship
    if ( !fd.fInitialized(ucacId, myId, friendId) ) {
      fd.fSetInitialized(ucacId, myId, friendId, true);
      fd.fSetf1Id(ucacId, myId, friendId, myId);
      fd.fSetf2Id(ucacId, myId, friendId, friendId);
      fd.fSetIsPending(ucacId, myId, friendId, true);
      fd.fSetf1Confirmed(ucacId, myId, friendId, true);

      fd.pushFriendId(ucacId, myId, friendId);
      fd.pushFriendId(ucacId, friendId, myId);
      return;
    }
    if ( fd.fIsMutual(ucacId, myId, friendId) ) return;

    if ( af.idEq(fd.ff1Id(ucacId, myId, friendId), myId) ) {
      fd.fSetf1Confirmed(ucacId, myId, friendId, true);
    }
    if ( af.idEq(fd.ff2Id(ucacId, myId, friendId), myId) ) {
      fd.fSetf2Confirmed(ucacId, myId, friendId, true);
    }

    //if friend has confirmed already, friendship is mutual
    if (
        ( af.idEq(fd.ff1Id(ucacId, myId, friendId), friendId) && fd.ff1Confirmed(ucacId, myId, friendId))
        ||
        ( af.idEq(fd.ff2Id(ucacId, myId, friendId), friendId) && fd.ff2Confirmed(ucacId, myId, friendId))) {
      fd.fSetIsMutual(ucacId, myId, friendId, true);
      fd.fSetIsPending(ucacId, myId, friendId, false);

      return;
    }
    //if friend hasn't confirmed, make this pending
    else {
      fd.fSetIsPending(ucacId, myId, friendId, true);
    }
  }

  function deleteFriend(bytes32 ucacId, bytes32 myId, bytes32 friendId) public onlyParent {
    //we keep initialized set to true so that the friendship doesn't get recreated
    fd.fSetf1Confirmed(ucacId, myId, friendId, false);
    fd.fSetf2Confirmed(ucacId, myId, friendId, false);

    fd.fSetIsMutual(ucacId, myId, friendId, false);
    fd.fSetIsPending(ucacId, myId, friendId, false);
  }
}
