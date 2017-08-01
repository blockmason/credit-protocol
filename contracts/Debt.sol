pragma solidity ^0.4.11;

import "./AbstractFIDData.sol";
import "./AbstractFoundation.sol";
import "./AbstractFriend.sol";

contract Debt {

  AbstractFoundation af;
  AbstractFriend afs;
  AbstractFIDData afd;

  bytes32 adminFoundationId;

  modifier isIdOwner(address _caller, bytes32 _name) {
    if ( ! af.isUnified(_caller, _name) ) revert();
    _;
  }

  modifier isAdmin(address _caller) {
    if ( ! af.idEq(adminFoundationId, af.resolveToName(_caller))) revert();
    _;
  }

  modifier currencyValid(bytes32 _currencyCode) {
    if ( ! afd.currencyValid(_currencyCode) ) revert();
    _;
  }

  modifier areFriends(bytes32 _id1, bytes32 _id2) {
    if ( ! afs.areFriends(_id1, _id2) ) revert();
    _;
  }

  function Debt(bytes32 _adminId, address dataContract, address friendContract, address foundationContract) {
    afd = AbstractFIDData(dataContract);
    afs = AbstractFriend(friendContract);
    af  = AbstractFoundation(foundationContract);
    adminFoundationId = _adminId;
  }

  function addCurrencyCode(bytes32 _currencyCode) public isAdmin(msg.sender) {
    afd.dSetCurrencyCode(_currencyCode, true);
  }

  function isActiveCurrency(bytes32 _currencyCode) constant returns (bool) {
    return afd.currencyValid(_currencyCode);
  }

  //T is for Temp
  uint debtIdT;
  bytes32 currencyT;
  int amountT;
  bytes32 descT;
  bytes32 debtorT;
  bytes32 creditorT;
  uint timestampT;
  bool isPendingT;
  bool isRejectedT;
  bool debtorConfirmedT;
  bool creditorConfirmedT;

  bytes32[] friendsT;
  uint[] debtIdsT;
  bytes32[] confirmersT;
  bytes32[] currenciesT;
  int[] amountsT;
  bytes32[] descsT;
  bytes32[] debtorsT;
  bytes32[] creditorsT;
  uint[] timestampsT;
  uint[] totalDebtsT;

  function setDebtVars(bytes32 p1, bytes32 p2, uint index) private {
    debtIdT = afd.dId(p1, p2, index);
    currencyT = afd.dCurrencyCode(p1, p2, index);
    amountT = afd.dAmount(p1, p2, index);
    descT = afd.dDesc(p1, p2, index);
    debtorT = afd.dDebtorId(p1, p2, index);
    creditorT = afd.dCreditorId(p1, p2, index);
    timestampT = afd.dTimestamp(p1, p2, index);
    isPendingT = afd.dIsPending(p1, p2, index);
    isRejectedT = afd.dIsRejected(p1, p2, index);
  }
  function setTimestamps(bytes32 p1, bytes32 p2, uint index) private {
    isPendingT = afd.dIsPending(p1, p2, index);
    timestampT = afd.dTimestamp(p1, p2, index);
  }

  function setFriendsT(bytes32 fId) private {
    friendsT.length = 0;
    for ( uint m=0; m < afs.numFriends(fId); m++ ) {
      bytes32 tmp = afs.friendIdByIndex(fId, m);
      friendsT.push(tmp);
    }
  }

  function pendingDebts(bytes32 fId) constant returns (uint[] debtIds, bytes32[] confirmerIds, bytes32[] currency, int[] amounts, bytes32[] descs, bytes32[] debtors, bytes32[] creditors) {
    setFriendsT(fId);

    debtIdsT.length = 0;
    confirmersT.length = 0;
    currenciesT.length = 0;
    amountsT.length = 0;
    descsT.length = 0;
    debtorsT.length = 0;
    creditorsT.length = 0;

    for ( uint i=0; i < friendsT.length; i++ ) {
      bytes32 friend = friendsT[i];
      for ( uint j=0; j < afd.numDebts(fId, friend); j++ ) {
        setDebtVars(fId, friend, j);

        if ( isPendingT ) {
          debtIdsT.push(debtIdT);
          currenciesT.push(currencyT);
          amountsT.push(amountT);
          descsT.push(descT);
          debtorsT.push(debtorT);
          creditorsT.push(creditorT);

          if ( afd.dDebtorConfirmed(fId, friend, j))
            confirmersT.push(creditorT);
          else
            confirmersT.push(debtorT);
        }
      }
    }
    return (debtIdsT, confirmersT, currenciesT, amountsT, descsT, debtorsT, creditorsT);
  }

  function pendingDebtTimestamps(bytes32 fId) constant returns (uint[] timestamps) {
    setFriendsT(fId);
    timestampsT.length = 0;
    for ( uint i=0; i < friendsT.length; i++ ) {
      bytes32 friend = friendsT[i];
      for ( uint j=0; j < afd.numDebts(fId, friend); j++ ) {
        setTimestamps(fId, friend, j);

        if ( isPendingT) {
          timestampsT.push(timestampT);
        }
      }
    }
    return timestampsT;
  }


  mapping ( bytes32 => mapping (bytes32 => int )) currencyToIdToAmount;
  bytes32[] cdCurrencies;
  //returns positive for debt owed, negative for owed from other party
  function confirmedDebtBalances(bytes32 fId) constant returns (bytes32[] currency, int[] amounts, bytes32[] counterpartyIds, uint[] totalDebts, uint[] mostRecent) {
    setFriendsT(fId);

    currenciesT.length = 0;
    amountsT.length = 0;
    creditorsT.length = 0;
    timestampsT.length = 0;
    totalDebtsT.length = 0;

    for ( uint i=0; i < friendsT.length; i++ ) {
      uint nDebts = 0;
      uint mostRecentTime = 0;
      bytes32 friend = friendsT[i];
      cdCurrencies.length = 0;
      for ( uint j=0; j < afd.numDebts(fId, friend); j++ ) {
        setDebtVars(fId, friend, j);

        nDebts++;
        if ( timestampT > mostRecentTime ) mostRecentTime = timestampT;

        if ( !isPendingT && !isRejectedT ) {
          if ( ! isMember(currencyT, cdCurrencies ))
            cdCurrencies.push(currencyT);
          if ( af.idEq(debtorT, fId) )
            currencyToIdToAmount[currencyT][friend] += amountT;
          else
            currencyToIdToAmount[currencyT][friend] -= amountT;
        }
      }
      for ( uint k=0; k < cdCurrencies.length; k++ ) {
        currenciesT.push(cdCurrencies[k]);
        amountsT.push(currencyToIdToAmount[cdCurrencies[k]][friend]);
        creditorsT.push(friend);
      }
      totalDebtsT.push(nDebts);
      timestampsT.push(mostRecentTime);
    }

    return (currenciesT, amountsT, creditorsT, totalDebtsT, timestampsT);
  }

  function confirmedDebts(bytes32 p1, bytes32 p2) constant returns (bytes32[] currency2, int[] amounts2, bytes32[] descs2, bytes32[] debtors2, bytes32[] creditors2, uint[] timestamps2) {
    currenciesT.length = 0;
    amountsT.length = 0;
    descsT.length = 0;
    debtorsT.length = 0;
    creditorsT.length = 0;
    timestampsT.length = 0;

    for ( uint i=0; i < afd.numDebts(p1, p2); i++ ) {
      setDebtVars(p1, p2, i);

      if ( !isPendingT && !isRejectedT ) {
        currenciesT.push(currencyT);
        amountsT.push(amountT);
        descsT.push(descT);
        debtorsT.push(debtorT);
        creditorsT.push(creditorT);
        timestampsT.push(timestampT);
      }
    }
    return (currenciesT, amountsT, descsT, debtorsT, creditorsT, timestampsT);
  }


  function newDebt(bytes32 debtorId, bytes32 creditorId, bytes32 currencyCode, int amount, bytes32 desc) currencyValid(currencyCode) areFriends(debtorId, creditorId) {
    if ( !af.isUnified(msg.sender, debtorId) && !af.isUnified(msg.sender, creditorId))
      revert();

    if ( amount <= 0 ) revert();

    if ( amount == 0 ) return;

    bytes32 confirmerName = af.resolveToName(msg.sender);
    uint debtId = afd.getNextDebtId();

    afd.pushBlankDebt(debtorId, creditorId);
    uint idx = afd.numDebts(debtorId, creditorId) - 1;

    afd.dSetId(debtorId, creditorId, idx, debtId);
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

    afd.dSetNextDebtId(debtId + 1);
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
