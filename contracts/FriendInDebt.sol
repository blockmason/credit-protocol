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
    initCurrencyCodes();
    nextDebtId = 0;
  }

  function initCurrencyCodes() private {
    currencyCodes[stringToBytes32("USDcents")] = true;
    currencyCodes[stringToBytes32("EURcents")] = true;
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

  function confirmedDebts(bytes32 p1, bytes32 p2) constant returns (bytes32[] currency, int[] amounts, bytes32[] descs, bytes32[] debtors, bytes32[] creditors)  {
    currencyD.length = 0;
    amountsD.length = 0;
    descsD.length = 0;
    debtorsD.length = 0;
    creditorsD.length = 0;
    for ( uint i=0; i<debts[p1][p2].length; i++ ) {
      Debt memory d = debts[p1][p2][i];
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

  //if debt amount is negative, debt is owed by friend to me
  function newDebt(bytes32 myId, bytes32 friendId, bytes32 currencyCode, int amount, bytes32 _desc) isIdOwner(msg.sender, myId) currencyValid(currencyCode) {
    if ( amount == 0 ) return;

    uint debtId = nextDebtId;
    nextDebtId++;
    Debt memory d;
    d.id = debtId;
    d.currencyCode = currencyCode;
    d.isPending = true;
    d.desc = _desc;


    if ( amount > 0 ) {
      d.amount = amount;
      d.debtorId = myId;
      d.creditorId = friendId;
      d.debtorConfirmed = true;
    }
    else {
      d.amount = amount * -1;
      d.debtorId = friendId;
      d.creditorId = myId;
      d.creditorConfirmed = true;
    }

    //if friend's debt array for me isn't initialized, use mine
    if ( debts[friendId][myId].length == 0 )
      debts[myId][friendId].push(d);
    else
      debts[friendId][myId].push(d);
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

  function stringToBytes32(string memory source) private constant returns (bytes32 result) {
    assembly {
        result := mload(add(source, 32))
    }
  }
}
