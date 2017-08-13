pragma solidity ^0.4.11;

import "./AbstractFoundation.sol";
import "./AbstractDPData.sol";

contract Friend {
  AbstractCPData acp;
  AbstractFoundation af;

  function Friend(address dataContract, address foundationContract) {
    acp = AbstractDPData(dataContract);
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
    for ( uint i = 0; i < acp.numDebts(p1, p2); i++ ) {
      bytes32 c = acp.dCurrencyCode(p1, p2, i);
      if ( ! isMember(c, currencies) ) {
        balByCurrency[c] = 0;
        currencies.push(c);
      }
      balByCurrency[c] += acp.dAmount(p1, p2, i);
    }
    //throw error if all balances aren't 0
    for ( uint j=0; j < currencies.length; j++ )
      if ( balByCurrency[currencies[j]] != 0 ) revert();
    _;
  }

  function areFriends(bytes32 _id1, bytes32 _id2) constant returns (bool) {
    return acp.fIsMutual(_id1, _id2);
  }

  function addFriend(bytes32 myId, bytes32 friendId) public isIdOwner(msg.sender, myId) {
    if ( af.idEq(myId, friendId) ) revert(); //can't add yourself

    //if not initialized, create the Friendship
    if ( !acp.fInitialized(myId, friendId) ) {
      acp.fSetInitialized(myId, friendId, true);
      acp.fSetf1Id(myId, friendId, myId);
      acp.fSetf2Id(myId, friendId, friendId);
      acp.fSetIsPending(myId, friendId, true);
      acp.fSetf1Confirmed(myId, friendId, true);

      acp.fSetInitialized(friendId, myId, true);
      acp.fSetf1Id(friendId, myId, myId);
      acp.fSetf2Id(friendId, myId, friendId);
      acp.fSetIsPending(friendId, myId, true);
      acp.fSetf1Confirmed(friendId, myId, true);

      acp.pushFriendId(myId, friendId);
      acp.pushFriendId(friendId, myId);
      return;
    }
    if ( acp.fIsMutual(myId, friendId) ) return;

    if ( af.idEq(acp.ff1Id(myId, friendId), myId) ) {
      acp.fSetf1Confirmed(myId, friendId, true);
      acp.fSetf1Confirmed(friendId, myId, true);
    }
    if ( af.idEq(acp.ff2Id(myId, friendId), myId) ) {
      acp.fSetf2Confirmed(myId, friendId, true);
      acp.fSetf2Confirmed(friendId, myId, true);
    }

    //if friend has confirmed already, friendship is mutual
    if (
        ( af.idEq(acp.ff1Id(myId, friendId), friendId) && acp.ff1Confirmed(myId, friendId))
        ||
        ( af.idEq(acp.ff2Id(myId, friendId), friendId) && acp.ff2Confirmed(myId, friendId))) {
      acp.fSetIsMutual(myId, friendId, true);
      acp.fSetIsPending(myId, friendId, false);

      acp.fSetIsMutual(friendId, myId, true);
      acp.fSetIsPending(friendId, myId, false);
      return;
    }
    //if friend hasn't confirmed, make this pending
    else {
      acp.fSetIsPending(myId, friendId, true);
      acp.fSetIsPending(friendId, myId, true);
    }
  }

  /*
     if these friends have ANY non-zero balance, throws an error
   */
  function deleteFriend(bytes32 myId, bytes32 friendId) public allBalancesZero(myId, friendId) isIdOwner(msg.sender, myId) {
    //we keep initialized set to true so that the friendship doesn't get recreated
    acp.fSetf1Confirmed(myId, friendId, false);
    acp.fSetf1Confirmed(friendId, myId, false);
    acp.fSetf2Confirmed(myId, friendId, false);
    acp.fSetf2Confirmed(friendId, myId, false);

    acp.fSetIsMutual(myId, friendId, false);
    acp.fSetIsMutual(friendId, myId, false);

    acp.fSetIsPending(myId, friendId, false);
    acp.fSetIsPending(friendId, myId, false);
  }

  /*  helpers  */
  function isMember(bytes32 s, bytes32[] l) constant returns(bool) {
    for ( uint i=0; i < l.length; i++ ) {
      if ( af.idEq(l[i], s)) return true;
    }
    return false;
  }

}
