pragma solidity ^0.4.11;

import "./AbstractCPData.sol";

contract DebtReader {

  AbstractCPData acp;

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

  function DataReader(address dataContract) {
    acp = AbstractCPData(dataContract);
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
  mapping ( bytes32 => mapping (bytes32 => uint )) currencyToIdToNumDebts;
  mapping ( bytes32 => mapping (bytes32 => uint )) currencyToIdToMostRecent;
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
      bytes32 friend = friendsT[i];
      cdCurrencies.length = 0;
      for ( uint j=0; j < afd.numDebts(fId, friend); j++ ) {
        setDebtVars(fId, friend, j);

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

  /*  helpers  */
  function isMember(bytes32 s, bytes32[] l) constant returns(bool) {
    for ( uint i=0; i < l.length; i++ ) {
      if ( af.idEq(l[i], s)) return true;
    }
    return false;
  }

}
