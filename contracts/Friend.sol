pragma solidity ^0.4.11;

import "./AbstractFoundation.sol";
import "./AbstractCPData.sol";

contract Friend {
  AbstractCPData add;
  AbstractFoundation af;

  function Friend(address dataContract, address foundationContract) {
    add = AbstractCPData(dataContract);
    af  = AbstractFoundation(foundationContract);
  }

  modifier isIdOwner(address _caller, bytes32 _name) {
    if ( ! af.isUnified(_caller, _name) ) revert();
    _;
  }

  mapping ( bytes32 => int ) balByCurrency;
  bytes32[] currencies;
  modifier allBalancesZero(bytes32 p1, bytes32 p2) {
    currencies.length = 0;
    for ( uint i = 0; i < add.numDebts(p1, p2); i++ ) {
      bytes32 c = add.dCurrencyCode(p1, p2, i);
      if ( ! isMember(c, currencies) ) {
        balByCurrency[c] = 0;
        currencies.push(c);
      }
      balByCurrency[c] += add.dAmount(p1, p2, i);
    }
    //throw error if all balances aren't 0
    for ( uint j=0; j < currencies.length; j++ )
      if ( balByCurrency[currencies[j]] != 0 ) revert();
    _;
  }

  function areFriends(bytes32 _id1, bytes32 _id2) constant returns (bool) {
    return add.fIsMutual(_id1, _id2);
  }

  function addFriend(bytes32 myId, bytes32 friendId) public isIdOwner(msg.sender, myId) {
    if ( af.idEq(myId, friendId) ) revert(); //can't add yourself

    //if not initialized, create the Friendship
    if ( !add.fInitialized(myId, friendId) ) {
      add.fSetInitialized(myId, friendId, true);
      add.fSetf1Id(myId, friendId, myId);
      add.fSetf2Id(myId, friendId, friendId);
      add.fSetIsPending(myId, friendId, true);
      add.fSetf1Confirmed(myId, friendId, true);

      add.fSetInitialized(friendId, myId, true);
      add.fSetf1Id(friendId, myId, myId);
      add.fSetf2Id(friendId, myId, friendId);
      add.fSetIsPending(friendId, myId, true);
      add.fSetf1Confirmed(friendId, myId, true);

      add.pushFriendId(myId, friendId);
      add.pushFriendId(friendId, myId);
      return;
    }
    if ( add.fIsMutual(myId, friendId) ) return;

    if ( af.idEq(add.ff1Id(myId, friendId), myId) ) {
      add.fSetf1Confirmed(myId, friendId, true);
      add.fSetf1Confirmed(friendId, myId, true);
    }
    if ( af.idEq(add.ff2Id(myId, friendId), myId) ) {
      add.fSetf2Confirmed(myId, friendId, true);
      add.fSetf2Confirmed(friendId, myId, true);
    }

    //if friend has confirmed already, friendship is mutual
    if (
        ( af.idEq(add.ff1Id(myId, friendId), friendId) && add.ff1Confirmed(myId, friendId))
        ||
        ( af.idEq(add.ff2Id(myId, friendId), friendId) && add.ff2Confirmed(myId, friendId))) {
      add.fSetIsMutual(myId, friendId, true);
      add.fSetIsPending(myId, friendId, false);

      add.fSetIsMutual(friendId, myId, true);
      add.fSetIsPending(friendId, myId, false);
      return;
    }
    //if friend hasn't confirmed, make this pending
    else {
      add.fSetIsPending(myId, friendId, true);
      add.fSetIsPending(friendId, myId, true);
    }
  }

  /*
     if these friends have ANY non-zero balance, throws an error
   */
  function deleteFriend(bytes32 myId, bytes32 friendId) public allBalancesZero(myId, friendId) isIdOwner(msg.sender, myId) {
    //we keep initialized set to true so that the friendship doesn't get recreated
    add.fSetf1Confirmed(myId, friendId, false);
    add.fSetf1Confirmed(friendId, myId, false);
    add.fSetf2Confirmed(myId, friendId, false);
    add.fSetf2Confirmed(friendId, myId, false);

    add.fSetIsMutual(myId, friendId, false);
    add.fSetIsMutual(friendId, myId, false);

    add.fSetIsPending(myId, friendId, false);
    add.fSetIsPending(friendId, myId, false);
  }

  function numFriends(bytes32 fId) constant returns (uint) {
    return add.numFriends(fId);
  }

  function friendIdByIndex(bytes32 fId, uint index) returns (bytes32) {
    return add.friendIdByIndex(fId, index);
  }

  /*  Temporary variables */
  bytes32[] ids1;
  bytes32[] ids2;
  function confirmedFriends(bytes32 fId) constant returns (bytes32[] confirmedFriends) {
    ids1.length = 0;
    for ( uint i=0; i < add.numFriends(fId); i++ ) {
      bytes32 currFriendId = friendIdByIndex(fId, i);
      if ( add.fIsMutual(fId, currFriendId) )
        ids1.push(currFriendId);
    }
    return ids1;
  }

  function pendingFriends(bytes32 fId) constant returns (bytes32[] friendIds, bytes32[] confirmerIds) {
    ids1.length = 0;
    ids2.length = 0;
    for ( uint i=0; i < add.numFriends(fId); i++ ) {
      bytes32 friendId = friendIdByIndex(fId, i);
      //      Friendship memory fs = friendships[fId][currFriendId];
      if ( add.fIsPending(fId, friendId) ) {
        ids1.push(friendId);
        if ( add.ff1Confirmed(fId, friendId) )
          ids2.push(add.ff2Id(fId, friendId));
        else
          ids2.push(add.ff1Id(fId, friendId));
      }
    }
    return (ids1, ids2);
  }

  /*  helpers  */
  function isMember(bytes32 s, bytes32[] l) constant returns(bool) {
    for ( uint i=0; i < l.length; i++ ) {
      if ( af.idEq(l[i], s)) return true;
    }
    return false;
  }

}
