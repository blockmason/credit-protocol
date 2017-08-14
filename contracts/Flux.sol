pragma solidity ^0.4.11;

/*  Flux
    The Flux Capacitor for Debt Protocol
*/

//TODO: all write calls should call out to the staker to see if the token/address they get back from the UCAC is cool

import "./AbstractUcac.sol";
import "./AbstractFriendData.sol";
import "./AbstractDebtData.sol";
import "./AbstractFriendReader.sol";
import "./AbstractFoundation.sol";

contract Flux {

  AbstractUcac au;
  AbstractDebtData add;
  AbstractFriendData afd;
  AbstractFriendReader afr;
  AbstractFoundation af;

  bytes32 adminFoundationId;
  bool mutex;

  function Flux(bytes32 _adminId, address debtContract, address friendContract, address friendReaderContract, address foundationContract) {
    add = AbstractDebtData(debtContract);
    afd = AbstractFriendData(friendContract);
    afr = AbstractFriendReader(friendReaderContract);
    af  = AbstractFoundation(foundationContract);
    adminFoundationId = _adminId;
  }

  /* Debt recording functions */
  function newDebt(address ucac, bytes32 debtorId, bytes32 creditorId, bytes32 currencyCode, int amount, bytes32 desc) public {
    if ( !af.isUnified(msg.sender, debtorId) && !af.isUnified(msg.sender, creditorId))
      revert();
    if ( amount == 0 ) return;
    if ( amount < 0 )  revert();

    au = AbstractUcac(ucac);

    add.pushBlankDebt(debtorId, creditorId);
    uint idx = add.numDebts(debtorId, creditorId) - 1;

    add.dSetUcac(debtorId, creditorId, idx, ucac);
    add.dSetId(debtorId, creditorId, idx, add.getNextDebtId());
    add.dSetTimestamp(debtorId, creditorId, idx, now);
    add.dSetAmount(debtorId, creditorId, idx, amount);
    add.dSetCurrencyCode(debtorId, creditorId, idx, currencyCode);
    add.dSetDebtorId(debtorId, creditorId, idx, debtorId);
    add.dSetCreditorId(debtorId, creditorId, idx, creditorId);
    add.dSetIsPending(debtorId, creditorId, idx, true);
    add.dSetDesc(debtorId, creditorId, idx, desc);

    if ( af.idEq(af.resolveToName(msg.sender), debtorId) )
      add.dSetDebtorConfirmed(debtorId, creditorId, idx, true);
    else
      add.dSetCreditorConfirmed(debtorId, creditorId, idx, true);

    add.dSetNextDebtId(add.getNextDebtId() + 1);
  }

  function confirmDebt(address ucac, bytes32 myId, bytes32 friendId, uint debtId) {
    uint index;
    bool success;
    (index, success) = findPendingDebt(myId, friendId, debtId);
    if ( ! success ) return;
    au = AbstractUcac(ucac);

    if ( af.idEq(myId, add.dDebtorId(myId, friendId, index)) && !add.dDebtorConfirmed(myId, friendId, index) && add.dCreditorConfirmed(myId, friendId, index) ) {
      add.dSetDebtorConfirmed(myId, friendId, index, true);
      add.dSetIsPending(myId, friendId, index, false);
    }
    if ( af.idEq(myId, add.dCreditorId(myId, friendId, index)) && !add.dCreditorConfirmed(myId, friendId, index) && add.dDebtorConfirmed(myId, friendId, index) ) {
      add.dSetCreditorConfirmed(myId, friendId, index, true);
      add.dSetIsPending(myId, friendId, index, false);
    }
  }

  function rejectDebt(address ucac, bytes32 myId, bytes32 friendId, uint debtId) public {
    uint index;
    bool success;
    (index, success) = findPendingDebt(myId, friendId, debtId);
    if ( ! success ) return;
    au = AbstractUcac(ucac);

    add.dSetIsPending(myId, friendId, index, false);
    add.dSetIsRejected(myId, friendId, index, true);
    add.dSetDebtorConfirmed(myId, friendId, index, false);
    add.dSetCreditorConfirmed(myId, friendId, index, false);
  }

  /* Friend functions */
  function addFriend(address ucac, bytes32 myId, bytes32 friendId) public {
    if ( af.idEq(myId, friendId) ) revert(); //can't add yourself
    au = AbstractUcac(ucac);

    //if not initialized, create the Friendship
    if ( !afd.fInitialized(myId, friendId) ) {
      afd.fSetUcac(myId, friendId, ucac);
      afd.fSetInitialized(myId, friendId, true);
      afd.fSetf1Id(myId, friendId, myId);
      afd.fSetf2Id(myId, friendId, friendId);
      afd.fSetIsPending(myId, friendId, true);
      afd.fSetf1Confirmed(myId, friendId, true);

      afd.pushFriendId(myId, friendId);
      afd.pushFriendId(friendId, myId);
      return;
    }
    if ( afd.fIsMutual(myId, friendId) ) return;

    if ( af.idEq(afd.ff1Id(myId, friendId), myId) ) {
      afd.fSetf1Confirmed(myId, friendId, true);
    }
    if ( af.idEq(afd.ff2Id(myId, friendId), myId) ) {
      afd.fSetf2Confirmed(myId, friendId, true);
    }

    //if friend has confirmed already, friendship is mutual
    if (
        ( af.idEq(afd.ff1Id(myId, friendId), friendId) && afd.ff1Confirmed(myId, friendId))
        ||
        ( af.idEq(afd.ff2Id(myId, friendId), friendId) && afd.ff2Confirmed(myId, friendId))) {
      afd.fSetIsMutual(myId, friendId, true);
      afd.fSetIsPending(myId, friendId, false);

      return;
    }
    //if friend hasn't confirmed, make this pending
    else {
      afd.fSetIsPending(myId, friendId, true);
    }
  }

  function deleteFriend(address ucac, bytes32 myId, bytes32 friendId) {
    au = AbstractUcac(ucac);
    //we keep initialized set to true so that the friendship doesn't get recreated
    afd.fSetf1Confirmed(myId, friendId, false);
    afd.fSetf2Confirmed(myId, friendId, false);

    afd.fSetIsMutual(myId, friendId, false);
    afd.fSetIsPending(myId, friendId, false);
  }

  /*  helpers and modifiers */
  function isMember(bytes32 s, bytes32[] l) constant returns(bool) {
    for ( uint i=0; i < l.length; i++ ) {
      if ( af.idEq(l[i], s)) return true;
    }
    return false;
  }

  modifier isAdmin(address _caller) {
    if ( ! af.idEq(adminFoundationId, af.resolveToName(_caller))) revert();
    _;
  }

  modifier areFriends(bytes32 _id1, bytes32 _id2) {
    if ( ! afr.areFriends(_id1, _id2) ) revert();
    _;
  }

  modifier oneIsSender(address _sender, bytes32 _id1, bytes32 _id2) {
    bytes32 _name = af.resolveToName(_sender);
    if ( !af.idEq(_name, _id1) && !af.idEq(_name, _id2) ) revert();
    _;
  }

  //returns false for success if debt not found
  //only returns pending, non-rejected debts
  function findPendingDebt(bytes32 p1, bytes32 p2, uint debtId) private constant returns (uint index, bool success) {
    for(uint i=0; i < add.numDebts(p1, p2); i++) {
      if( add.dId(p1, p2, i) == debtId && add.dIsPending(p1, p2, i)
          && ! add.dIsRejected(p1, p2, i) )
        return (i, true);
    }
    return (i, false);
  }

  function getMyFoundationId() constant returns (bytes32 foundationId) {
    return af.resolveToName(msg.sender);
  }
}
