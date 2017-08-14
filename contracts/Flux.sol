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

  bytes32 admin;
  bool mutex;
  bool allowed;
  address provider;
  address idUcac;

  function Flux(bytes32 _adminId, address debtContract, address friendContract, address friendReaderContract, address foundationContract) {
    add = AbstractDebtData(debtContract);
    afd = AbstractFriendData(friendContract);
    afr = AbstractFriendReader(friendReaderContract);
    af  = AbstractFoundation(foundationContract);
    admin = _adminId;
  }

  /* Debt recording functions */
  function newDebt(address ucac, bytes32 debtorId, bytes32 creditorId, bytes32 currencyCode, int amount, bytes32 desc) public isMutexed {
    if ( amount == 0 ) revert();
    if ( amount < 0 )  revert();
    au = AbstractUcac(ucac);
    (allowed, provider, idUcac) = au.newDebt(msg.sender, debtorId, creditorId, currencyCode, amount, desc);
    if ( !allowed ) revert();

    add.pushBlankDebt(idUcac, debtorId, creditorId);
    uint idx = add.numDebts(idUcac, debtorId, creditorId) - 1;

    add.dSetId(idUcac, debtorId, creditorId, idx, add.getNextDebtId());
    add.dSetTimestamp(idUcac, debtorId, creditorId, idx, now);
    add.dSetAmount(idUcac, debtorId, creditorId, idx, amount);
    add.dSetCurrencyCode(idUcac, debtorId, creditorId, idx, currencyCode);
    add.dSetDebtorId(idUcac, debtorId, creditorId, idx, debtorId);
    add.dSetCreditorId(idUcac, debtorId, creditorId, idx, creditorId);
    add.dSetIsPending(idUcac, debtorId, creditorId, idx, true);
    add.dSetDesc(idUcac, debtorId, creditorId, idx, desc);

    if ( af.idEq(af.resolveToName(msg.sender), debtorId) )
      add.dSetDebtorConfirmed(idUcac, debtorId, creditorId, idx, true);
    else
      add.dSetCreditorConfirmed(idUcac, debtorId, creditorId, idx, true);

    add.dSetNextDebtId(add.getNextDebtId() + 1);
  }

  function confirmDebt(address ucac, bytes32 myId, bytes32 friendId, uint debtId) public isMutexed {
    uint index;
    bool success;
    (index, success) = findPendingDebt(idUcac, myId, friendId, debtId);
    if ( ! success ) return;
    au = AbstractUcac(ucac);
    (allowed, provider, idUcac) = au.confirmDebt(msg.sender, myId, friendId, debtId);
    if ( !allowed ) revert();

    if ( af.idEq(myId, add.dDebtorId(idUcac, myId, friendId, index)) && !add.dDebtorConfirmed(idUcac, myId, friendId, index) && add.dCreditorConfirmed(idUcac, myId, friendId, index) ) {
      add.dSetDebtorConfirmed(idUcac, myId, friendId, index, true);
      add.dSetIsPending(idUcac, myId, friendId, index, false);
    }
    if ( af.idEq(myId, add.dCreditorId(idUcac, myId, friendId, index)) && !add.dCreditorConfirmed(idUcac, myId, friendId, index) && add.dDebtorConfirmed(idUcac, myId, friendId, index) ) {
      add.dSetCreditorConfirmed(idUcac, myId, friendId, index, true);
      add.dSetIsPending(idUcac, myId, friendId, index, false);
    }
  }

  function rejectDebt(address ucac, bytes32 myId, bytes32 friendId, uint debtId) public isMutexed {
    uint index;
    bool success;
    (index, success) = findPendingDebt(idUcac, myId, friendId, debtId);
    if ( ! success ) return;
    au = AbstractUcac(ucac);
    (allowed, provider, idUcac) = au.rejectDebt(msg.sender, myId, friendId, debtId);
    if ( !allowed ) revert();

    add.dSetIsPending(idUcac, myId, friendId, index, false);
    add.dSetIsRejected(idUcac, myId, friendId, index, true);
    add.dSetDebtorConfirmed(idUcac, myId, friendId, index, false);
    add.dSetCreditorConfirmed(idUcac, myId, friendId, index, false);
  }

  /* Friend functions */
  function addFriend(address ucac, bytes32 myId, bytes32 friendId) public isMutexed {
    if ( af.idEq(myId, friendId) ) revert(); //can't add yourself as a friend
    au = AbstractUcac(ucac);
    (allowed, provider, idUcac) = au.addFriend(msg.sender, myId, friendId);
    if ( !allowed ) revert();

    //if not initialized, create the Friendship
    if ( !afd.fInitialized(idUcac, myId, friendId) ) {
      afd.fSetInitialized(idUcac, myId, friendId, true);
      afd.fSetf1Id(idUcac, myId, friendId, myId);
      afd.fSetf2Id(idUcac, myId, friendId, friendId);
      afd.fSetIsPending(idUcac, myId, friendId, true);
      afd.fSetf1Confirmed(idUcac, myId, friendId, true);

      afd.pushFriendId(idUcac, myId, friendId);
      afd.pushFriendId(idUcac, friendId, myId);
      return;
    }
    if ( afd.fIsMutual(idUcac, myId, friendId) ) return;

    if ( af.idEq(afd.ff1Id(idUcac, myId, friendId), myId) ) {
      afd.fSetf1Confirmed(idUcac, myId, friendId, true);
    }
    if ( af.idEq(afd.ff2Id(idUcac, myId, friendId), myId) ) {
      afd.fSetf2Confirmed(idUcac, myId, friendId, true);
    }

    //if friend has confirmed already, friendship is mutual
    if (
        ( af.idEq(afd.ff1Id(idUcac, myId, friendId), friendId) && afd.ff1Confirmed(idUcac, myId, friendId))
        ||
        ( af.idEq(afd.ff2Id(idUcac, myId, friendId), friendId) && afd.ff2Confirmed(idUcac, myId, friendId))) {
      afd.fSetIsMutual(idUcac, myId, friendId, true);
      afd.fSetIsPending(idUcac, myId, friendId, false);

      return;
    }
    //if friend hasn't confirmed, make this pending
    else {
      afd.fSetIsPending(idUcac, myId, friendId, true);
    }
  }

  function deleteFriend(address ucac, bytes32 myId, bytes32 friendId) public isMutexed {
    au = AbstractUcac(ucac);
    (allowed, provider, idUcac) = au.deleteFriend(msg.sender, myId, friendId);
    if ( !allowed ) revert();

    //we keep initialized set to true so that the friendship doesn't get recreated
    afd.fSetf1Confirmed(idUcac, myId, friendId, false);
    afd.fSetf2Confirmed(idUcac, myId, friendId, false);

    afd.fSetIsMutual(idUcac, myId, friendId, false);
    afd.fSetIsPending(idUcac, myId, friendId, false);
  }

  /*  helpers and modifiers */
  modifier isAdmin(address _caller) {
    if ( ! af.idEq(admin, af.resolveToName(_caller))) revert();
    _;
  }

  modifier areFriends(address ucac, bytes32 _id1, bytes32 _id2) {
    if ( ! afr.areFriends(idUcac, _id1, _id2) ) revert();
    _;
  }

  modifier oneIsSender(address _sender, bytes32 _id1, bytes32 _id2) {
    bytes32 _name = af.resolveToName(_sender);
    if ( !af.idEq(_name, _id1) && !af.idEq(_name, _id2) ) revert();
    _;
  }

  modifier isMutexed() {
    require ( !mutex );
    mutex = true;
    _;
    mutex = false;
  }

  //returns false for success if debt not found
  //only returns pending, non-rejected debts
  function findPendingDebt(address ucac, bytes32 p1, bytes32 p2, uint debtId) private constant returns (uint index, bool success) {
    for(uint i=0; i < add.numDebts(idUcac, p1, p2); i++) {
      if( add.dId(idUcac, p1, p2, i) == debtId && add.dIsPending(idUcac, p1, p2, i)
          && ! add.dIsRejected(idUcac, p1, p2, i) )
        return (i, true);
    }
    return (i, false);
  }
}
