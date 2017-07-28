pragma solidity ^0.4.11;

contract AbstractFIDData {

  /* main functions */
  function FIDData(address _admin2);


  function setDebtContract(address _debtContract);
  function setFriendContract(address _friendContract);
  function getDebtContract() constant returns (address debtContract);
  function getFriendContract() constant returns (address friendContract);
  function getAdmins() constant returns (address admin, address admin2);

  /* Friend Getters */
  function numFriends(bytes32 fId) constant returns (uint);
  function friendIdByIndex(bytes32 fId, uint index) constant returns (bytes32);
  function fInitialized(bytes32 p1, bytes32 p2) constant returns (bool);
  function ff1Id(bytes32 p1, bytes32 p2) constant returns (bytes32);
  function ff2Id(bytes32 p1, bytes32 p2) constant returns (bytes32);
  function fIsPending(bytes32 p1, bytes32 p2) constant returns (bool);
  function fIsMutual(bytes32 p1, bytes32 p2) constant returns (bool);
  function ff1Confirmed(bytes32 p1, bytes32 p2) constant returns (bool);
  function ff2Confirmed(bytes32 p1, bytes32 p2) constant returns (bool);

  /* Friend Setters */
  function pushFriendId(bytes32 myId, bytes32 friendId);
  function setFriendIdByIndex(bytes32 myId, uint idx, bytes32 newFriendId);
  function fSetInitialized(bytes32 p1, bytes32 p2, bool initialized);
  function fSetf1Id(bytes32 p1, bytes32 p2, bytes32 id);
  function fSetf2Id(bytes32 p1, bytes32 p2, bytes32 id);
  function fSetIsPending(bytes32 p1, bytes32 p2, bool isPending);
  function fSetIsMutual(bytes32 p1, bytes32 p2, bool isMutual);
  function fSetf1Confirmed(bytes32 p1, bytes32 p2, bool f1Confirmed);
  function fSetf2Confirmed(bytes32 p1, bytes32 p2, bool f2Confirmed);

  /* Debt helpers */
  bytes32 f;
  bytes32 s;
  function debtIndices(bytes32 p1, bytes32 p2) constant returns (bytes32 first, bytes32 second);

  /* Debt Getters   */
  function numDebts(bytes32 p1, bytes32 p2) constant returns (uint numDebts);
  function currencyValid(bytes32 currencyCode) constant returns (bool);
  function getNextDebtId() constant returns (uint);
  function dId(bytes32 p1, bytes32 p2, uint idx) constant returns (uint id);
  function dTimestamp (bytes32 p1, bytes32 p2, uint idx) constant returns (uint timestamp);
  function dAmount(bytes32 p1, bytes32 p2, uint idx) constant returns (int amount);
  function dCurrencyCode(bytes32 p1, bytes32 p2, uint idx) constant returns (bytes32 currencyCode);
  function dDebtorId(bytes32 p1, bytes32 p2, uint idx) constant returns (bytes32 debtorId);
  function dCreditorId(bytes32 p1, bytes32 p2, uint idx) constant returns (bytes32 creditorId);
  function dIsPending(bytes32 p1, bytes32 p2, uint idx) constant returns (bool isPending);
  function dIsRejected(bytes32 p1, bytes32 p2, uint idx) constant returns (bool isRejected);
  function dDebtorConfirmed (bytes32 p1, bytes32 p2, uint idx) constant returns (bool debtorConfirmed);
  function dCreditorConfirmed (bytes32 p1, bytes32 p2, uint idx) constant returns (bool creditorConfirmed);
  function dDesc(bytes32 p1, bytes32 p2, uint idx) constant returns (bytes32 desc);

  /* Debt Setters   */
  function dSetCurrencyCode(bytes32 currencyCode, bool val);
  function dSetNextDebtId(uint newId);
  function pushBlankDebt(bytes32 p1, bytes32 p2);
  function dSetId(bytes32 p1, bytes32 p2, uint idx, uint id);
  function dSetTimestamp(bytes32 p1, bytes32 p2, uint idx, uint timestamp);
  function dSetAmount(bytes32 p1, bytes32 p2, uint idx, int amount);
  function dSetCurrencyCode(bytes32 p1, bytes32 p2, uint idx, bytes32 currencyCode);
  function dSetDebtorId(bytes32 p1, bytes32 p2, uint idx, bytes32 debtorId);
  function dSetCreditorId(bytes32 p1, bytes32 p2, uint idx, bytes32 creditorId);
  function dSetIsPending(bytes32 p1, bytes32 p2, uint idx, bool isPending);
  function dSetIsRejected(bytes32 p1, bytes32 p2, uint idx, bool isRejected);
  function dSetDebtorConfirmed(bytes32 p1, bytes32 p2, uint idx, bool debtorConfirmed);
  function dSetCreditorConfirmed(bytes32 p1, bytes32 p2, uint idx, bool creditorConfirmed);
  function dSetDesc(bytes32 p1, bytes32 p2, uint idx, bytes32 desc);

}
