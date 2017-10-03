pragma solidity ^0.4.15;

import "./DebtData.sol";
import "./FriendInterface.sol";
import "./AbstractFoundation.sol";

contract DebtInterface is Parentable {

  DebtData dd;
  FriendInterface fi;
  AbstractFoundation af;

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

  function DebtInterface(address _debtDataContract, address _friendInterfaceContract, address _foundationContract) {
    dd = DebtData(_debtDataContract);
    fi = FriendInterface(_friendInterfaceContract);
    af  = AbstractFoundation(_foundationContract);
  }

  function numDebts(bytes32 ucacId, bytes32 p1, bytes32 p2) constant returns (uint) {
    return dd.numDebts(ucacId, p1, p2);
  }

  function setDebtVars(bytes32 ucacId, bytes32 p1, bytes32 p2, uint index) private {
    debtIdT = dd.dId(ucacId, p1, p2, index);
    currencyT = dd.dCurrencyCode(ucacId, p1, p2, index);
    amountT = dd.dAmount(ucacId, p1, p2, index);
    descT = dd.dDesc(ucacId, p1, p2, index);
    debtorT = dd.dDebtorId(ucacId, p1, p2, index);
    creditorT = dd.dCreditorId(ucacId, p1, p2, index);
    timestampT = dd.dTimestamp(ucacId, p1, p2, index);
    isPendingT = dd.dIsPending(ucacId, p1, p2, index);
    isRejectedT = dd.dIsRejected(ucacId, p1, p2, index);
  }
  function setTimestamps(bytes32 ucacId, bytes32 p1, bytes32 p2, uint index) private {
    isPendingT = dd.dIsPending(ucacId, p1, p2, index);
    timestampT = dd.dTimestamp(ucacId, p1, p2, index);
  }

  function setFriendsT(bytes32 ucacId, bytes32 fId) private {
    friendsT.length = 0;
    for ( uint m=0; m < fi.numFriends(ucacId, fId); m++ ) {
      bytes32 tmp = fi.friendIdByIndex(ucacId, fId, m);
      friendsT.push(tmp);
    }
  }

  function pendingDebts(bytes32 ucacId, bytes32 fId) constant returns (uint[] debtIds, bytes32[] confirmerIds, bytes32[] currency, int[] amounts, bytes32[] descs, bytes32[] debtors, bytes32[] creditors) {
    setFriendsT(ucacId, fId);

    debtIdsT.length = 0;
    confirmersT.length = 0;
    currenciesT.length = 0;
    amountsT.length = 0;
    descsT.length = 0;
    debtorsT.length = 0;
    creditorsT.length = 0;

    for ( uint i=0; i < friendsT.length; i++ ) {
      bytes32 friend = friendsT[i];
      for ( uint j=0; j < dd.numDebts(ucacId, fId, friend); j++ ) {
        setDebtVars(ucacId, fId, friend, j);

        if ( isPendingT ) {
          debtIdsT.push(debtIdT);
          currenciesT.push(currencyT);
          amountsT.push(amountT);
          descsT.push(descT);
          debtorsT.push(debtorT);
          creditorsT.push(creditorT);

          if ( dd.dDebtorConfirmed(ucacId, fId, friend, j))
            confirmersT.push(creditorT);
          else
            confirmersT.push(debtorT);
        }
      }
    }
    return (debtIdsT, confirmersT, currenciesT, amountsT, descsT, debtorsT, creditorsT);
  }

  function pendingDebtTimestamps(bytes32 ucacId, bytes32 fId) constant returns (uint[] timestamps) {
    setFriendsT(ucacId, fId);
    timestampsT.length = 0;
    for ( uint i=0; i < friendsT.length; i++ ) {
      bytes32 friend = friendsT[i];
      for ( uint j=0; j < dd.numDebts(ucacId, fId, friend); j++ ) {
        setTimestamps(ucacId, fId, friend, j);

        if ( isPendingT) {
          timestampsT.push(timestampT);
        }
      }
    }
    return timestampsT;
  }

  mapping ( bytes32 => mapping (bytes32 => int )) currencyToIdToAmount;
  mapping ( bytes32 => mapping (bytes32 => uint )) currencyToIdToNumDebts;
  mapping ( bytes32 => mapping (bytes32 => uint )) currencyToIdToMostRecent;
  bytes32[] cdCurrencies;
  //returns positive for debt owed, negative for owed from other party
  function confirmedDebtBalances(bytes32 ucacId, bytes32 fId) constant returns (bytes32[] currency, int[] amounts, bytes32[] counterpartyIds, uint[] totalDebts, uint[] mostRecent) {
    setFriendsT(ucacId, fId);

    currenciesT.length = 0;
    amountsT.length = 0;
    creditorsT.length = 0;
    timestampsT.length = 0;
    totalDebtsT.length = 0;

    for ( uint i=0; i < friendsT.length; i++ ) {
      bytes32 friend = friendsT[i];
      cdCurrencies.length = 0;
      for ( uint j=0; j < dd.numDebts(ucacId, fId, friend); j++ ) {
        setDebtVars(ucacId, fId, friend, j);

        //run this logic if the debt is neither Pending nor Rejected
        if ( !isPendingT && !isRejectedT ) {
          if ( ! isMember(currencyT, cdCurrencies )) {
            currencyToIdToAmount[currencyT][friend] = 0;
            currencyToIdToNumDebts[currencyT][friend] = 0;
            currencyToIdToMostRecent[currencyT][friend] = 0;
            cdCurrencies.push(currencyT);
          }
          currencyToIdToNumDebts[currencyT][friend] += 1;
          if ( timestampT > currencyToIdToMostRecent[currencyT][friend] )
            currencyToIdToMostRecent[currencyT][friend] = timestampT;
          if ( af.idEq(debtorT, fId) )
            currencyToIdToAmount[currencyT][friend] += amountT;
          else
            currencyToIdToAmount[currencyT][friend] -= amountT;
        }
      }
      for ( uint k=0; k < cdCurrencies.length; k++ ) {
        if ( currencyToIdToAmount[cdCurrencies[k]][friend] != 0 ) {
          currenciesT.push(cdCurrencies[k]);
          amountsT.push(currencyToIdToAmount[cdCurrencies[k]][friend]);
          creditorsT.push(friend);
          totalDebtsT.push(currencyToIdToNumDebts[currencyT][friend]);
          timestampsT.push(currencyToIdToMostRecent[currencyT][friend]);
        }
      }
    }

    return (currenciesT, amountsT, creditorsT, totalDebtsT, timestampsT);
  }

  function confirmedDebts(bytes32 ucacId, bytes32 p1, bytes32 p2) constant returns (bytes32[] currency2, int[] amounts2, bytes32[] descs2, bytes32[] debtors2, bytes32[] creditors2, uint[] timestamps2) {
    currenciesT.length = 0;
    amountsT.length = 0;
    descsT.length = 0;
    debtorsT.length = 0;
    creditorsT.length = 0;
    timestampsT.length = 0;

    for ( uint i=0; i < dd.numDebts(ucacId, p1, p2); i++ ) {
      setDebtVars(ucacId, p1, p2, i);

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

  /* Debt recording functions */
  function newDebt(bytes32 ucacId, bytes32 debtorId, bytes32 creditorId, bytes32 currencyCode, int amount, bytes32 desc) public onlyParent {
    if ( amount == 0 ) revert();
    if ( amount < 0 )  revert();

    dd.pushBlankDebt(ucacId, debtorId, creditorId);
    uint idx = dd.numDebts(ucacId, debtorId, creditorId) - 1;

    dd.dSetId(ucacId, debtorId, creditorId, idx, dd.nextDebtId());
    dd.dSetTimestamp(ucacId, debtorId, creditorId, idx, now);
    dd.dSetAmount(ucacId, debtorId, creditorId, idx, amount);
    dd.dSetCurrencyCode(ucacId, debtorId, creditorId, idx, currencyCode);
    dd.dSetDebtorId(ucacId, debtorId, creditorId, idx, debtorId);
    dd.dSetCreditorId(ucacId, debtorId, creditorId, idx, creditorId);
    dd.dSetIsPending(ucacId, debtorId, creditorId, idx, true);
    dd.dSetDesc(ucacId, debtorId, creditorId, idx, desc);

    if ( af.idEq(af.resolveToName(msg.sender), debtorId) )
      dd.dSetDebtorConfirmed(ucacId, debtorId, creditorId, idx, true);
    else
      dd.dSetCreditorConfirmed(ucacId, debtorId, creditorId, idx, true);

    dd.incrementDebtId();
  }

  function confirmDebt(bytes32 ucacId, bytes32 myId, bytes32 friendId, uint debtId) public onlyParent {
    uint index;
    bool success;
    (index, success) = findPendingDebt(ucacId, myId, friendId, debtId);
    if ( ! success ) return;

    if ( af.idEq(myId, dd.dDebtorId(ucacId, myId, friendId, index)) && !dd.dDebtorConfirmed(ucacId, myId, friendId, index) && dd.dCreditorConfirmed(ucacId, myId, friendId, index) ) {
      dd.dSetDebtorConfirmed(ucacId, myId, friendId, index, true);
      dd.dSetIsPending(ucacId, myId, friendId, index, false);
    }
    if ( af.idEq(myId, dd.dCreditorId(ucacId, myId, friendId, index)) && !dd.dCreditorConfirmed(ucacId, myId, friendId, index) && dd.dDebtorConfirmed(ucacId, myId, friendId, index) ) {
      dd.dSetCreditorConfirmed(ucacId, myId, friendId, index, true);
      dd.dSetIsPending(ucacId, myId, friendId, index, false);
    }
  }

  function rejectDebt(bytes32 ucacId, bytes32 myId, bytes32 friendId, uint debtId) public onlyParent {
    uint index;
    bool success;
    (index, success) = findPendingDebt(ucacId, myId, friendId, debtId);
    if ( ! success ) return;

    dd.dSetIsPending(ucacId, myId, friendId, index, false);
    dd.dSetIsRejected(ucacId, myId, friendId, index, true);
    dd.dSetDebtorConfirmed(ucacId, myId, friendId, index, false);
    dd.dSetCreditorConfirmed(ucacId, myId, friendId, index, false);
  }

  /*  helpers  */
  function isMember(bytes32 s, bytes32[] l) constant returns(bool) {
    for ( uint i=0; i < l.length; i++ ) {
      if ( af.idEq(l[i], s)) return true;
    }
    return false;
  }

  /** returns false for success if debt not found
   only returns pending, non-rejected debts
  **/
  function findPendingDebt(bytes32 ucacId, bytes32 p1, bytes32 p2, uint debtId) private constant returns (uint index, bool success) {
    for(uint i=0; i < dd.numDebts(ucacId, p1, p2); i++) {
      if( dd.dId(ucacId, p1, p2, i) == debtId && dd.dIsPending(ucacId, p1, p2, i)
          && ! dd.dIsRejected(ucacId, p1, p2, i) )
        return (i, true);
    }
    return (i, false);
  }

}
