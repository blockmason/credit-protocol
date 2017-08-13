pragma solidity ^0.4.11;

/*  Flux
    The Flux Capacitor for Debt Protocol
*/

//TODO: all write calls should call out to the staker to see if the token/address they get back from the UCAC is cool

import "./AbstractUcac.sol";
import "./AbstractCPData.sol";
import "./AbstractFriendReader.sol";
import "./AbstractFoundation.sol";

contract Flux {

  AbstractUcac au;
  AbstractCPData acp;
  AbstractFriendReader afr;
  AbstractFoundation af;

  bytes32 adminFoundationId;

  function Flux(bytes32 _adminId, address dataContract, address friendReaderContract, address foundationContract) {
    acp = AbstractCPData(dataContract);
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

    acp.pushBlankDebt(debtorId, creditorId);
    uint idx = acp.numDebts(debtorId, creditorId) - 1;

    acp.dSetUcac(debtorId, creditorId, idx, ucac);
    acp.dSetId(debtorId, creditorId, idx, acp.getNextDebtId());
    acp.dSetTimestamp(debtorId, creditorId, idx, now);
    acp.dSetAmount(debtorId, creditorId, idx, amount);
    acp.dSetCurrencyCode(debtorId, creditorId, idx, currencyCode);
    acp.dSetDebtorId(debtorId, creditorId, idx, debtorId);
    acp.dSetCreditorId(debtorId, creditorId, idx, creditorId);
    acp.dSetIsPending(debtorId, creditorId, idx, true);
    acp.dSetDesc(debtorId, creditorId, idx, desc);

    if ( af.idEq(af.resolveToName(msg.sender), debtorId) )
      acp.dSetDebtorConfirmed(debtorId, creditorId, idx, true);
    else
      acp.dSetCreditorConfirmed(debtorId, creditorId, idx, true);

    acp.dSetNextDebtId(acp.getNextDebtId() + 1);
  }

  function confirmDebt(address ucac, bytes32 myId, bytes32 friendId, uint debtId) {
    uint index;
    bool success;
    (index, success) = findPendingDebt(myId, friendId, debtId);
    if ( ! success ) return;
    au = AbstractUcac(ucac);

    if ( af.idEq(myId, acp.dDebtorId(myId, friendId, index)) && !acp.dDebtorConfirmed(myId, friendId, index) && acp.dCreditorConfirmed(myId, friendId, index) ) {
      acp.dSetDebtorConfirmed(myId, friendId, index, true);
      acp.dSetIsPending(myId, friendId, index, false);
    }
    if ( af.idEq(myId, acp.dCreditorId(myId, friendId, index)) && !acp.dCreditorConfirmed(myId, friendId, index) && acp.dDebtorConfirmed(myId, friendId, index) ) {
      acp.dSetCreditorConfirmed(myId, friendId, index, true);
      acp.dSetIsPending(myId, friendId, index, false);
    }
  }

  function rejectDebt(address ucac, bytes32 myId, bytes32 friendId, uint debtId) public {
    uint index;
    bool success;
    (index, success) = findPendingDebt(myId, friendId, debtId);
    if ( ! success ) return;
    au = AbstractUcac(ucac);

    acp.dSetIsPending(myId, friendId, index, false);
    acp.dSetIsRejected(myId, friendId, index, true);
    acp.dSetDebtorConfirmed(myId, friendId, index, false);
    acp.dSetCreditorConfirmed(myId, friendId, index, false);
  }

  /* Friend functions */
  function addFriend(address ucac, bytes32 myId, bytes32 friendId) public {
    if ( af.idEq(myId, friendId) ) revert(); //can't add yourself
    au = AbstractUcac(ucac);

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


  //   if these friends have ANY non-zero balance, throws an error

  function deleteFriend(address ucac, bytes32 myId, bytes32 friendId) public allBalancesZero(myId, friendId) isIdOwner(msg.sender, myId) {
    au = AbstractUcac(ucac);

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

  //returns false for success if debt not found
  //only returns pending, non-rejected debts
  function findPendingDebt(bytes32 p1, bytes32 p2, uint debtId) private constant returns (uint index, bool success) {
    for(uint i=0; i < acp.numDebts(p1, p2); i++) {
      if( acp.dId(p1, p2, i) == debtId && acp.dIsPending(p1, p2, i)
          && ! acp.dIsRejected(p1, p2, i) )
        return (i, true);
    }
    return (i, false);
  }

  function getMyFoundationId() constant returns (bytes32 foundationId) {
    return af.resolveToName(msg.sender);
  }
}
