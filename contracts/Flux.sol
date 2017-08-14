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
    (allowed, provider) = au.newDebt(msg.sender, debtorId, creditorId, currencyCode, amount, desc);
    if ( !allowed ) revert();

    add.pushBlankDebt(ucac, debtorId, creditorId);
    uint idx = add.numDebts(ucac, debtorId, creditorId) - 1;

    add.dSetId(ucac, debtorId, creditorId, idx, add.getNextDebtId());
    add.dSetTimestamp(ucac, debtorId, creditorId, idx, now);
    add.dSetAmount(ucac, debtorId, creditorId, idx, amount);
    add.dSetCurrencyCode(ucac, debtorId, creditorId, idx, currencyCode);
    add.dSetDebtorId(ucac, debtorId, creditorId, idx, debtorId);
    add.dSetCreditorId(ucac, debtorId, creditorId, idx, creditorId);
    add.dSetIsPending(ucac, debtorId, creditorId, idx, true);
    add.dSetDesc(ucac, debtorId, creditorId, idx, desc);

    if ( af.idEq(af.resolveToName(msg.sender), debtorId) )
      add.dSetDebtorConfirmed(ucac, debtorId, creditorId, idx, true);
    else
      add.dSetCreditorConfirmed(ucac, debtorId, creditorId, idx, true);

    add.dSetNextDebtId(add.getNextDebtId() + 1);
  }

  function confirmDebt(address ucac, bytes32 myId, bytes32 friendId, uint debtId) public isMutexed {
    uint index;
    bool success;
    (index, success) = findPendingDebt(ucac, myId, friendId, debtId);
    if ( ! success ) return;
    au = AbstractUcac(ucac);
    (allowed, provider) = au.confirmDebt(msg.sender, myId, friendId, debtId);
    if ( !allowed ) revert();

    if ( af.idEq(myId, add.dDebtorId(ucac, myId, friendId, index)) && !add.dDebtorConfirmed(ucac, myId, friendId, index) && add.dCreditorConfirmed(ucac, myId, friendId, index) ) {
      add.dSetDebtorConfirmed(ucac, myId, friendId, index, true);
      add.dSetIsPending(ucac, myId, friendId, index, false);
    }
    if ( af.idEq(myId, add.dCreditorId(ucac, myId, friendId, index)) && !add.dCreditorConfirmed(ucac, myId, friendId, index) && add.dDebtorConfirmed(ucac, myId, friendId, index) ) {
      add.dSetCreditorConfirmed(ucac, myId, friendId, index, true);
      add.dSetIsPending(ucac, myId, friendId, index, false);
    }
  }

  function rejectDebt(address ucac, bytes32 myId, bytes32 friendId, uint debtId) public isMutexed {
    uint index;
    bool success;
    (index, success) = findPendingDebt(ucac, myId, friendId, debtId);
    if ( ! success ) return;
    au = AbstractUcac(ucac);
    (allowed, provider) = au.rejectDebt(msg.sender, myId, friendId, debtId);
    if ( !allowed ) revert();

    add.dSetIsPending(ucac, myId, friendId, index, false);
    add.dSetIsRejected(ucac, myId, friendId, index, true);
    add.dSetDebtorConfirmed(ucac, myId, friendId, index, false);
    add.dSetCreditorConfirmed(ucac, myId, friendId, index, false);
  }

  /* Friend functions */
  function addFriend(address ucac, bytes32 myId, bytes32 friendId) public isMutexed {
    if ( af.idEq(myId, friendId) ) revert(); //can't add yourself as a friend
    au = AbstractUcac(ucac);
    (allowed, provider) = au.addFriend(msg.sender, myId, friendId);
    if ( !allowed ) revert();

    //if not initialized, create the Friendship
    if ( !afd.fInitialized(ucac, myId, friendId) ) {
      afd.fSetInitialized(ucac, myId, friendId, true);
      afd.fSetf1Id(ucac, myId, friendId, myId);
      afd.fSetf2Id(ucac, myId, friendId, friendId);
      afd.fSetIsPending(ucac, myId, friendId, true);
      afd.fSetf1Confirmed(ucac, myId, friendId, true);

      afd.pushFriendId(ucac, myId, friendId);
      afd.pushFriendId(ucac, friendId, myId);
      return;
    }
    if ( afd.fIsMutual(ucac, myId, friendId) ) return;

    if ( af.idEq(afd.ff1Id(ucac, myId, friendId), myId) ) {
      afd.fSetf1Confirmed(ucac, myId, friendId, true);
    }
    if ( af.idEq(afd.ff2Id(ucac, myId, friendId), myId) ) {
      afd.fSetf2Confirmed(ucac, myId, friendId, true);
    }

    //if friend has confirmed already, friendship is mutual
    if (
        ( af.idEq(afd.ff1Id(ucac, myId, friendId), friendId) && afd.ff1Confirmed(ucac, myId, friendId))
        ||
        ( af.idEq(afd.ff2Id(ucac, myId, friendId), friendId) && afd.ff2Confirmed(ucac, myId, friendId))) {
      afd.fSetIsMutual(ucac, myId, friendId, true);
      afd.fSetIsPending(ucac, myId, friendId, false);

      return;
    }
    //if friend hasn't confirmed, make this pending
    else {
      afd.fSetIsPending(ucac, myId, friendId, true);
    }
  }

  function deleteFriend(address ucac, bytes32 myId, bytes32 friendId) public isMutexed {
    au = AbstractUcac(ucac);
    (allowed, provider) = au.deleteFriend(msg.sender, myId, friendId);
    if ( !allowed ) revert();

    //we keep initialized set to true so that the friendship doesn't get recreated
    afd.fSetf1Confirmed(ucac, myId, friendId, false);
    afd.fSetf2Confirmed(ucac, myId, friendId, false);

    afd.fSetIsMutual(ucac, myId, friendId, false);
    afd.fSetIsPending(ucac, myId, friendId, false);
  }

  /*  helpers and modifiers */
  modifier isAdmin(address _caller) {
    if ( ! af.idEq(admin, af.resolveToName(_caller))) revert();
    _;
  }

  modifier areFriends(address ucac, bytes32 _id1, bytes32 _id2) {
    if ( ! afr.areFriends(ucac, _id1, _id2) ) revert();
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
    for(uint i=0; i < add.numDebts(ucac, p1, p2); i++) {
      if( add.dId(ucac, p1, p2, i) == debtId && add.dIsPending(ucac, p1, p2, i)
          && ! add.dIsRejected(ucac, p1, p2, i) )
        return (i, true);
    }
    return (i, false);
  }
}
