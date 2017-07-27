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

  function FriendInDebt(bytes32 _adminId, address dataContract, address friendContract, address foundationContract) {
    afd = AbstractFIDData(dataContract);
    afs = AbstractFriend(friendContract);
    af  = AbstractFoundation(foundationContract);
    adminFoundationId = _adminId;
    initCurrencyCodes();
  }

  function initCurrencyCodes() private {
    afd.dSetCurrencyCode(bytes32("USD"), true);
    afd.dSetCurrencyCode(bytes32("EUR"), true);
  }


  function addCurrencyCode(bytes32 _currencyCode) isAdmin(msg.sender) {
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
    amountT= afd.dAmount(p1, p2, index);
    descT = afd.dDesc(p1, p2, index);
    debtorT = afd.dDebtorId(p1, p2, index);
    creditorT = afd.dCreditorId(p1, p2, index);
    timestampT = afd.dTimestamp(p1, p2, index);
    isPendingT = afd.dIsPending(p1, p2, index);
    isRejectedT = afd.dIsRejected(p1, p2, index);
  }
  function setTimestamps(bytes32 p1, bytes32 p2, uint index) private {
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
    return (debtIdsT, confirmersT, currenciesT, amountsT, descsT, debtorsT, creditorsT);
  }

  function pendingDebtTimestamps(bytes32 fId) constant returns (uint[] timestamps) {
    setFriendsT(fId);
    timestampsT.length = 0;
    for ( uint i=0; i < friendsT.length; i++ ) {
      bytes32 friend = friendsT[i];
      for ( uint j=0; j < afd.numDebts(fId, friend); j++ ) {
        setTimestamps(fId, friend, j);
        timestampsT.push(timestampT);
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
  /*

  function confirmedDebts(bytes32 p1, bytes32 p2) debtIndices(p1, p2) constant returns (bytes32[] currency, int[] amounts, bytes32[] descs, bytes32[] debtors, bytes32[] creditors) {
    currencyD.length = 0;
    amountsD.length = 0;
    descsD.length = 0;
    debtorsD.length = 0;
    creditorsD.length = 0;
    for ( uint i=0; i < debts[first][second].length; i++ ) {
      Debt memory d = debts[first][second][i];
      if ( ! d.isPending && ! d.isRejected ) {
        currencyD.push(d.currencyCode);
        amountsD.push(d.amount);
        descsD.push(d.desc);
        debtorsD.push(d.debtorId);
        creditorsD.push(d.creditorId);
      }
    }
    return (currencyD, amountsD, descsD, debtorsD, creditorsD);
  }

  function newDebt(bytes32 debtorId, bytes32 creditorId, bytes32 currencyCode, int amount, bytes32 _desc) currencyValid(currencyCode) areFriends(debtorId, creditorId) {
    if ( !af.isUnified(msg.sender, debtorId) && !af.isUnified(msg.sender, creditorId))
      revert();

    if ( amount == 0 ) return;

    bytes32 confirmerName = af.resolveToName(msg.sender);

    uint debtId = nextDebtId;
    nextDebtId++;
    Debt memory d;
    d.id = debtId;
    d.timestamp = now;
    d.currencyCode = currencyCode;
    d.isPending = true;
    d.desc = _desc;
    d.amount = amount;
    d.debtorId = debtorId;
    d.creditorId = creditorId;

    if ( af.idEq(confirmerName, debtorId) )
      d.debtorConfirmed = true;
    else
      d.creditorConfirmed = true;

    //if first debt array for me isn't initialized, use second
    if ( debts[debtorId][creditorId].length == 0 )
      debts[creditorId][debtorId].push(d);
    else
      debts[debtorId][creditorId].push(d);
  }

  function confirmDebt(bytes32 myId, bytes32 friendId, uint debtId) debtIndices(myId, friendId) isIdOwner(msg.sender, myId) {
    uint index;
    bool success;
    (index, success) = findPendingDebt(myId, friendId, debtId);
    if ( ! success ) return;
    Debt memory d = debts[first][second][index];
    if ( af.idEq(myId, d.debtorId) && !d.debtorConfirmed && d.creditorConfirmed )
      d.debtorConfirmed = true;
    if ( af.idEq(myId, d.creditorId) && !d.creditorConfirmed && d.debtorConfirmed )
      d.creditorConfirmed = true;
    d.isPending = false;
    debts[first][second][index] = d;
  }

  function rejectDebt(bytes32 myId, bytes32 friendId, uint debtId) debtIndices(myId, friendId) isIdOwner(msg.sender, myId) {
    uint index;
    bool success;
    (index, success) = findPendingDebt(myId, friendId, debtId);
    if ( ! success ) return;
    Debt memory d = debts[first][second][index];
    d.isPending = false;
    d.isRejected = true;
    d.debtorConfirmed = false;
    d.creditorConfirmed = false;
    debts[first][second][index] = d;
  }



  function getMyFoundationId() constant returns (bytes32 foundationId) {
    return af.resolveToName(msg.sender);
  }

  function idMember(bytes32 s, bytes32[] l) constant returns(bool) {
    for ( uint i=0; i<l.length; i++ ) {
      if ( af.idEq(l[i], s)) return true;
    }
    return false;
  }

  function currencyMember(bytes32 s, bytes32[] l) constant returns(bool) {
    for ( uint i=0; i<l.length; i++ ) {
      if ( af.idEq(l[i], s)) return true;
    }
    return false;
  }

  //returns false for success if debt not found
  //only returns pending, non-rejected debts
  function findPendingDebt(bytes32 p1, bytes32 p2, uint debtId) debtIndices(p1, p2) private constant returns (uint index, bool success) {
    bytes32 f = p1;
    bytes32 s = p2;
    if ( debts[f][s].length == 0 ) {
      f = p2;
      s = p1;
    }
    for(uint i=0; i<debts[f][s].length; i++) {
      if( debts[f][s][i].id == debtId && debts[f][s][i].isPending
          && ! debts[f][s][i].isRejected )
        return (i, true);
    }
    return (i, false);
  }

*/
  /*  helpers  */
  function isMember(bytes32 s, bytes32[] l) constant returns(bool) {
    for ( uint i=0; i < l.length; i++ ) {
      if ( af.idEq(l[i], s)) return true;
    }
    return false;
  }

}
