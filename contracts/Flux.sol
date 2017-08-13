pragma solidity ^0.4.11;

/*  Flux
    The Flux Capacitor for Debt Protocol
*/

import "./AbstractCPData.sol";
import "./AbstractFoundation.sol";
import "./AbstractFriend.sol";

contract Flux {

  AbstractFoundation af;
  AbstractFriend afs;
  AbstractCPData acp;

  bytes32 adminFoundationId;

  modifier isIdOwner(address _caller, bytes32 _name) {
    if ( ! af.isUnified(_caller, _name) ) revert();
    _;
  }

  modifier isAdmin(address _caller) {
    if ( ! af.idEq(adminFoundationId, af.resolveToName(_caller))) revert();
    _;
  }

  modifier areFriends(bytes32 _id1, bytes32 _id2) {
    if ( ! afs.areFriends(_id1, _id2) ) revert();
    _;
  }

  modifier oneIsSender(address _sender, bytes32 _id1, bytes32 _id2) {
    bytes32 _name = af.resolveToName(_sender);
    if ( !af.idEq(_name, _id1) && !af.idEq(_name, _id2) ) revert();
    _;
  }

  function Flux(bytes32 _adminId, address dataContract, address friendContract, address foundationContract) {
    afd = AbstractDPData(dataContract);
    afs = AbstractFriend(friendContract);
    af  = AbstractFoundation(foundationContract);
    adminFoundationId = _adminId;
  }

  function newDebt(address ucac, bytes32 debtorId, bytes32 creditorId, bytes32 currencyCode, int amount, bytes32 desc) oneIsSender(msg.sender, debtorId, creditorId) areFriends(debtorId, creditorId) {
    if ( !af.isUnified(msg.sender, debtorId) && !af.isUnified(msg.sender, creditorId))
      revert();

    if ( amount == 0 ) return;
    if ( amount < 0 )  revert();

    bytes32 confirmerName = af.resolveToName(msg.sender);

    afd.pushBlankDebt(debtorId, creditorId);
    uint idx = afd.numDebts(debtorId, creditorId) - 1;

    afd.dSetUcac(debtorId, creditorId, idx, ucac);
    afd.dSetId(debtorId, creditorId, idx, afd.getNextDebtId());
    afd.dSetTimestamp(debtorId, creditorId, idx, now);
    afd.dSetAmount(debtorId, creditorId, idx, amount);
    afd.dSetCurrencyCode(debtorId, creditorId, idx, currencyCode);
    afd.dSetDebtorId(debtorId, creditorId, idx, debtorId);
    afd.dSetCreditorId(debtorId, creditorId, idx, creditorId);
    afd.dSetIsPending(debtorId, creditorId, idx, true);
    afd.dSetDesc(debtorId, creditorId, idx, desc);

    if ( af.idEq(confirmerName, debtorId) )
      afd.dSetDebtorConfirmed(debtorId, creditorId, idx, true);
    else
      afd.dSetCreditorConfirmed(debtorId, creditorId, idx, true);

    afd.dSetNextDebtId(afd.getNextDebtId() + 1);
  }

  function confirmDebt(bytes32 myId, bytes32 friendId, uint debtId) isIdOwner(msg.sender, myId) {
    uint index;
    bool success;
    (index, success) = findPendingDebt(myId, friendId, debtId);
    if ( ! success ) return;

    if ( af.idEq(myId, afd.dDebtorId(myId, friendId, index)) && !afd.dDebtorConfirmed(myId, friendId, index) && afd.dCreditorConfirmed(myId, friendId, index) ) {
      afd.dSetDebtorConfirmed(myId, friendId, index, true);
      afd.dSetIsPending(myId, friendId, index, false);
    }
    if ( af.idEq(myId, afd.dCreditorId(myId, friendId, index)) && !afd.dCreditorConfirmed(myId, friendId, index) && afd.dDebtorConfirmed(myId, friendId, index) ) {
      afd.dSetCreditorConfirmed(myId, friendId, index, true);
      afd.dSetIsPending(myId, friendId, index, false);
    }
  }


  function rejectDebt(bytes32 myId, bytes32 friendId, uint debtId) isIdOwner(msg.sender, myId) {
    uint index;
    bool success;
    (index, success) = findPendingDebt(myId, friendId, debtId);
    if ( ! success ) return;

    afd.dSetIsPending(myId, friendId, index, false);
    afd.dSetIsRejected(myId, friendId, index, true);
    afd.dSetDebtorConfirmed(myId, friendId, index, false);
    afd.dSetCreditorConfirmed(myId, friendId, index, false);
  }

  /*  helpers  */
  function isMember(bytes32 s, bytes32[] l) constant returns(bool) {
    for ( uint i=0; i < l.length; i++ ) {
      if ( af.idEq(l[i], s)) return true;
    }
    return false;
  }

    //returns false for success if debt not found
  //only returns pending, non-rejected debts
  function findPendingDebt(bytes32 p1, bytes32 p2, uint debtId) private constant returns (uint index, bool success) {
    for(uint i=0; i < afd.numDebts(p1, p2); i++) {
      if( afd.dId(p1, p2, i) == debtId && afd.dIsPending(p1, p2, i)
          && ! afd.dIsRejected(p1, p2, i) )
        return (i, true);
    }
    return (i, false);
  }

  function getMyFoundationId() constant returns (bytes32 foundationId) {
    return af.resolveToName(msg.sender);
  }
}
