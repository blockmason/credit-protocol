pragma solidity ^0.4.11;

import "./AbstractFoundation.sol";

/* TODO

   2 users have at most 1 debt between them, going one direction
 */

contract FriendInDebt {

  AbstractFoundation af;
  bytes32 adminFoundationId;
  mapping ( bytes32 => bool ) currencyCodes;
  uint nextDebtId;

  struct Debt {
    uint id;
    int amount;
    bytes32 currencyCode;
    bytes32 debtorId;
    bytes32 creditorId;
    bool isPending;
    bool isRejected;
    bool debtorConfirmed;
    bool creditorConfirmed;
    bytes32 desc;
  }

  struct Friendship {
    bool initialized;
    bytes32 f1Id;
    bytes32 f2Id;
    bool isPending;
    bool isMutual;
    bool f1Confirmed;
    bool f2Confirmed;
  }

  mapping ( bytes32 => bytes32[] ) friendIdList;
  mapping ( bytes32 => mapping ( bytes32 => Friendship )) friendships;
  //only goes one way-- debts[X][Y] means there's no debts [Y][Z]
  mapping ( bytes32 => mapping ( bytes32 => Debt[] )) debts;

  //global variables to be used in functions
  bytes32 first; //these two order indices in the debts mapping
  bytes32 second;

  modifier isIdOwner(address _caller, bytes32 _name) {
    if ( ! af.isUnified(_caller, _name) ) throw;
    _;
  }

  modifier isAdmin(address _caller) {
    if ( ! af.idEq(adminFoundationId, af.resolveToName(_caller))) throw;
    _;
  }

  modifier currencyValid(bytes32 _currencyCode) {
    if ( ! currencyCodes[_currencyCode] ) throw;
    _;
  }

  modifier areFriends(bytes32 _id1, bytes32 _id2) {
    if ( ! friendships[_id1][_id2].isMutual ) throw;
    _;
  }

  modifier debtIndices(bytes32 p1, bytes32 p2) {
    first = p1;
    second = p2;
    if ( debts[p1][p2].length == 0 ) {
      first = p2;
      second = p1;
    }
    _;
  }

  function FriendInDebt(bytes32 _adminId, address foundationContract) {
    af = AbstractFoundation(foundationContract);
    adminFoundationId = _adminId;
    nextDebtId = 0;
  }

  function addCurrencyCode(bytes32 _currencyCode) isAdmin(msg.sender) {
    currencyCodes[_currencyCode] = true;
  }

  function isActiveCurrency(bytes32 _currencyCode) constant returns (bool) {
    return currencyCodes[_currencyCode];
  }

  function addFriend(bytes32 myId, bytes32 friendId) isIdOwner(msg.sender, myId) {
    Friendship memory fs = friendships[myId][friendId];
    //if not initialized, create the Friendship
    if ( !fs.initialized ) {
      fs.initialized = true;
      fs.f1Id = myId;
      fs.f2Id = friendId;
      fs.isPending = true;
      fs.f1Confirmed = true;

      friendIdList[myId].push(friendId);
      friendIdList[friendId].push(myId);

      friendships[myId][friendId] = fs;
      friendships[friendId][myId] = fs;
      return;
    }
    if ( fs.isMutual ) return;

    if ( af.idEq(fs.f1Id, myId) ) fs.f1Confirmed = true;
    if ( af.idEq(fs.f2Id, myId) ) fs.f2Confirmed = true;

    //if friend has confirmed already, friendship is mutual
    if ( ( af.idEq(fs.f1Id, friendId) && fs.f1Confirmed)
         ||
         ( af.idEq(fs.f2Id, friendId) && fs.f2Confirmed) ) {
      fs.isMutual = true;
      fs.isPending = false;

      friendships[myId][friendId] = fs;
      friendships[friendId][myId] = fs;
      return;
    }
    //if friend hasn't confirmed, make this pending
    else {
      fs.isPending = true;

      friendships[myId][friendId] = fs;
      friendships[friendId][myId] = fs;
    }
  }

  bytes32[] cFriends; //"local" variable for fn
  function confirmedFriends(bytes32 _foundationId) constant returns (bytes32[]) {
    cFriends.length = 0;
    for ( uint i=0; i<friendIdList[_foundationId].length; i++ ) {
      bytes32 currFriendId = friendIdList[_foundationId][i];
      if ( friendships[_foundationId][currFriendId].isMutual )
        cFriends.push(currFriendId);
    }
    return cFriends;
  }

  bytes32[] pFriends; //"local" variable for fn
  bytes32[] idsNeededToConfirmF;
  function pendingFriends(bytes32 _foundationId) constant returns (bytes32[] friendIds, bytes32[] confirmerIds) {
    pFriends.length = 0;
    for ( uint i=0; i<friendIdList[_foundationId].length; i++ ) {
      bytes32 currFriendId = friendIdList[_foundationId][i];
      Friendship memory fs = friendships[_foundationId][currFriendId];
      if ( fs.isPending ) {
        pFriends.push(currFriendId);
        if ( fs.f1Confirmed )
          idsNeededToConfirmF.push(fs.f2Id);
        else
          idsNeededToConfirmF.push(fs.f1Id);
      }
    }
    return (pFriends, idsNeededToConfirmF);
  }

  uint[] pDebts; //"local"
  bytes32[] idsNeededToConfirmD;
  bytes32[] currencyD;
  int[] amountsD;
  bytes32[] descsD;
  bytes32[] debtorsD;
  bytes32[] creditorsD;
  function pendingDebts(bytes32 p1, bytes32 p2)  debtIndices(p1, p2) constant returns (uint[] debtIds, bytes32[] confirmerIds, bytes32[] currency, int[] amounts, bytes32[] descs, bytes32[] debtors, bytes32[] creditors) {
    pDebts.length = 0;
    idsNeededToConfirmD.length = 0;
    currencyD.length = 0;
    amountsD.length = 0;
    descsD.length = 0;
    debtorsD.length = 0;
    creditorsD.length = 0;
    for ( uint i=0; i < debts[first][second].length; i++ ) {
      Debt memory d = debts[first][second][i];
      if ( d.isPending ) {
        pDebts.push(d.id);
        currencyD.push(d.currencyCode);
        amountsD.push(d.amount);
        descsD.push(d.desc);
        debtorsD.push(d.debtorId);
        creditorsD.push(d.creditorId);
        if ( d.debtorConfirmed )
          idsNeededToConfirmD.push(d.creditorId);
        else
          idsNeededToConfirmD.push(d.debtorId);
      }
    }
    return (pDebts, idsNeededToConfirmD, currencyD, amountsD, descsD, debtorsD, creditorsD);
  }

  mapping ( bytes32 => mapping (bytes32 => int )) currencyToIdToAmount;
  bytes32[] cdCurrencies;
  int[] amountsCD;
  //returns positive for debt owed, negative for owed from other party
  function confirmedDebtBalances(bytes32 _foundationId) constant returns (bytes32[] currency, int[] amounts, bytes32[] counterpartyIds) {
    bytes32[] memory friends = confirmedFriends(_foundationId);
    currencyD.length = 0;
    amountsCD.length = 0;
    creditorsD.length = 0;
    for( uint i=0; i < friends.length; i++ ) {
      bytes32 cFriend = friends[i];
      cdCurrencies.length = 0;
      Debt[] memory d1 = debts[_foundationId][cFriend];
      Debt[] memory d2 = debts[cFriend][_foundationId];
      Debt[] memory ds;
      if ( d1.length == 0 )
        ds = d2;
      else
        ds = d1;
      for ( uint j=0; j < ds.length; j++ ) {
        if ( !ds[j].isPending && !ds[j].isRejected ) {
          if ( ! currencyMember(ds[j].currencyCode, cdCurrencies) )
            cdCurrencies.push(ds[j].currencyCode);
          if ( af.idEq(ds[j].debtorId, _foundationId) )
            currencyToIdToAmount[ds[j].currencyCode][cFriend] += ds[j].amount;
          else
            currencyToIdToAmount[ds[j].currencyCode][cFriend] -= ds[j].amount;
        }
      }
      for ( uint k=0; k < cdCurrencies.length; k++ ) {
        currencyD.push(cdCurrencies[k]);
        amountsCD.push(currencyToIdToAmount[cdCurrencies[k]][cFriend]);
        creditorsD.push(cFriend);
      }
    }
    return (currencyD, amountsCD, creditorsD);
  }

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

  function newDebt(bytes32 debtorId, bytes32 creditorId, bytes32 currencyCode, int amount, bytes32 _desc) currencyValid(currencyCode) {
    if ( !af.isUnified(msg.sender, debtorId) && !af.isUnified(msg.sender, creditorId))
      throw;

    if ( amount == 0 ) return;

    bytes32 confirmerName = af.resolveToName(msg.sender);

    uint debtId = nextDebtId;
    nextDebtId++;
    Debt memory d;
    d.id = debtId;
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

  /***********  Helpers  ************/
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
}
