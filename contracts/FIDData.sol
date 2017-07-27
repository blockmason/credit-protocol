pragma solidity ^0.4.11;

contract FIDData {
  address admin;
  address admin2;
  address debtContract;
  address friendContract;

  /*  Friend  */
  struct Friend {
    bool initialized;
    bytes32 f1Id;
    bytes32 f2Id;
    bool isPending;
    bool isMutual;
    bool f1Confirmed;
    bool f2Confirmed;
  }
  mapping ( bytes32 => bytes32[] ) friendIdList;
  mapping ( bytes32 => mapping ( bytes32 => Friend )) friendships;

  /*  Debt  */
  mapping ( bytes32 => bool ) currencyCodes;
  uint nextDebtId;
  struct Debt {
    uint id;
    uint timestamp;
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
  mapping ( bytes32 => mapping ( bytes32 => Debt[] )) debts;
  Debt blankDebt; //Used to push onto debts

  /*  modifiers  */
  modifier isAdmin() {
    if ( (admin != msg.sender) && (admin2 != msg.sender)) revert();
    _;
  }

  modifier isParent() {
    if ( (msg.sender != debtContract) && (msg.sender != friendContract)) revert();
    _;
  }

  /* main functions */
  function FIDData(address _admin2) {
    admin = msg.sender;
    admin2 = _admin2;
  }

  function setDebtContract(address _debtContract) public isAdmin {
    debtContract = _debtContract;
  }
  function setFriendContract(address _friendContract) public isAdmin {
    friendContract = _friendContract;
  }
  function getDebtContract() constant returns (address debtContract) {
    return debtContract;
  }
  function getFriendContract() constant returns (address friendContract) {
    return friendContract;
  }
  function getAdmins() constant returns (address admin, address admin2) {
    return (admin, admin2);
  }

  /* Friend Getters */
  function numFriends(bytes32 fId) constant returns (uint) {
    return friendIdList[fId].length;
  }
  function friendIdByIndex(bytes32 fId, uint index) constant returns (bytes32) {
    return friendIdList[fId][index];
  }
  function fInitialized(bytes32 p1, bytes32 p2) constant returns (bool) {
    return friendships[p1][p2].initialized;
  }
  function ff1Id(bytes32 p1, bytes32 p2) constant returns (bytes32) {
    return friendships[p1][p2].f1Id;
  }
  function ff2Id(bytes32 p1, bytes32 p2) constant returns (bytes32) {
    return friendships[p1][p2].f2Id;
  }
  function fIsPending(bytes32 p1, bytes32 p2) constant returns (bool) {
    return friendships[p1][p2].isPending;
  }
  function fIsMutual(bytes32 p1, bytes32 p2) constant returns (bool) {
    return friendships[p1][p2].isMutual;
  }
  function ff1Confirmed(bytes32 p1, bytes32 p2) constant returns (bool) {
    return friendships[p1][p2].f1Confirmed;
  }
  function ff2Confirmed(bytes32 p1, bytes32 p2) constant returns (bool) {
    return friendships[p1][p2].f2Confirmed;
  }

  /* Friend Setters */
  function pushFriendId(bytes32 myId, bytes32 friendId) public isParent {
    friendIdList[myId].push(friendId);
  }
  function setFriendIdByIndex(bytes32 myId, uint idx, bytes32 newFriendId) public isParent{
    friendIdList[myId][idx] = newFriendId;
  }

  function fSetInitialized(bytes32 p1, bytes32 p2, bool initialized) public isParent {
    friendships[p1][p2].initialized = initialized;
  }
  function fSetf1Id(bytes32 p1, bytes32 p2, bytes32 id) public isParent {
    friendships[p1][p2].f1Id = id;
  }
  function fSetf2Id(bytes32 p1, bytes32 p2, bytes32 id) public isParent {
    friendships[p1][p2].f2Id = id;
  }
  function fSetIsPending(bytes32 p1, bytes32 p2, bool isPending) public isParent {
    friendships[p1][p2].isPending = isPending;
  }
  function fSetIsMutual(bytes32 p1, bytes32 p2, bool isMutual) public isParent {
    friendships[p1][p2].isMutual = isMutual;
  }
  function fSetf1Confirmed(bytes32 p1, bytes32 p2, bool f1Confirmed) public isParent {
    friendships[p1][p2].f1Confirmed = f1Confirmed;
  }
  function fSetf2Confirmed(bytes32 p1, bytes32 p2, bool f2Confirmed) public isParent {
    friendships[p1][p2].f2Confirmed = f2Confirmed;
  }

  /* Debt helpers */
  bytes32 f;
  bytes32 s;
  function debtIndices(bytes32 p1, bytes32 p2) constant returns (bytes32 first, bytes32 second) {
    if ( debts[p1][p2].length > 0 )
      return (p1, p2);
    else
      return (p2, p1);
  }

  /* Debt Getters   */
  function numDebts(bytes32 p1, bytes32 p2) constant returns (uint numDebts) {
    (f, s) = debtIndices(p1, p2);
    return debts[f][s].length;
  }
  function currencyValid(bytes32 currencyCode) constant returns (bool) {
    return currencyCodes[currencyCode];
  }
  function getNextDebtId() constant returns (uint) {
    return nextDebtId;
  }

  function dId(bytes32 p1, bytes32 p2, uint idx) constant returns (uint id) {
    (f, s) = debtIndices(p1, p2);
    return debts[f][s][idx].id;
  }
  function dTimestamp (bytes32 p1, bytes32 p2, uint idx) constant returns (uint timestamp) {
    (f, s) = debtIndices(p1, p2);
    return debts[f][s][idx].timestamp;
  }
  function dAmount(bytes32 p1, bytes32 p2, uint idx) constant returns (int amount) {
    (f, s) = debtIndices(p1, p2);
    return debts[f][s][idx].amount;
  }
  function dCurrencyCode(bytes32 p1, bytes32 p2, uint idx) constant returns (bytes32 currencyCode) {
    (f, s) = debtIndices(p1, p2);
    return debts[f][s][idx].currencyCode;
  }
  function dDebtorId(bytes32 p1, bytes32 p2, uint idx) constant returns (bytes32 debtorId) {
    (f, s) = debtIndices(p1, p2);
    return debts[f][s][idx].debtorId;
  }
  function dCreditorId(bytes32 p1, bytes32 p2, uint idx) constant returns (bytes32 creditorId) {
    (f, s) = debtIndices(p1, p2);
    return debts[f][s][idx].creditorId;
  }
  function dIsPending(bytes32 p1, bytes32 p2, uint idx) constant returns (bool isPending) {
    (f, s) = debtIndices(p1, p2);
    return debts[f][s][idx].isPending;
  }
  function dIsRejected(bytes32 p1, bytes32 p2, uint idx) constant returns (bool isRejected) {
    (f, s) = debtIndices(p1, p2);
    return debts[f][s][idx].isRejected;
  }
  function dDebtorConfirmed (bytes32 p1, bytes32 p2, uint idx) constant returns (bool debtorConfirmed) {
    (f, s) = debtIndices(p1, p2);
    return debts[f][s][idx].debtorConfirmed;
  }
  function dCreditorConfirmed (bytes32 p1, bytes32 p2, uint idx) constant returns (bool creditorConfirmed) {
    (f, s) = debtIndices(p1, p2);
    return debts[f][s][idx].creditorConfirmed;
  }
  function dDesc(bytes32 p1, bytes32 p2, uint idx) constant returns (bytes32 desc) {
    (f, s) = debtIndices(p1, p2);
    return debts[f][s][idx].desc;
  }

  /* Debt Setters   */
  function dSetCurrencyCode(bytes32 currencyCode) public isParent {
    currencyCodes[currencyCode] = true;
  }
  function dSetNextDebtId(uint newId) public isParent {
    nextDebtId = newId;
  }
  function pushBlankDebt(bytes32 p1, bytes32 p2) public isParent {
    (f, s) = debtIndices(p1, p2);
    debts[f][s].push(blankDebt);
  }

  function dSetId(bytes32 p1, bytes32 p2, uint idx, uint id) public isParent {
    (f, s) = debtIndices(p1, p2);
    debts[f][s][idx].id = id;
  }
  function dSetTimestamp(bytes32 p1, bytes32 p2, uint idx, uint timestamp) public isParent {
    (f, s) = debtIndices(p1, p2);
    debts[f][s][idx].timestamp = timestamp;
  }
  function dSetAmount(bytes32 p1, bytes32 p2, uint idx, int amount) public isParent {
    (f, s) = debtIndices(p1, p2);
    debts[f][s][idx].amount = amount;
  }
  function dSetCurrencyCode(bytes32 p1, bytes32 p2, uint idx, bytes32 currencyCode) public isParent {
    (f, s) = debtIndices(p1, p2);
    debts[f][s][idx].currencyCode = currencyCode;
  }
  function dSetDebtorId(bytes32 p1, bytes32 p2, uint idx, bytes32 debtorId) public isParent {
    (f, s) = debtIndices(p1, p2);
    debts[f][s][idx].debtorId = debtorId;
  }
  function dSetCreditorId(bytes32 p1, bytes32 p2, uint idx, bytes32 creditorId) public isParent {
    (f, s) = debtIndices(p1, p2);
    debts[f][s][idx].creditorId = creditorId;
  }
  function dSetIsPending(bytes32 p1, bytes32 p2, uint idx, bool isPending) public isParent {
    (f, s) = debtIndices(p1, p2);
    debts[f][s][idx].isPending = isPending;
  }
  function dSetIsRejected(bytes32 p1, bytes32 p2, uint idx, bool isRejected) public isParent {
    (f, s) = debtIndices(p1, p2);
    debts[f][s][idx].isRejected = isRejected;
  }
  function dSetDebtorConfirmed(bytes32 p1, bytes32 p2, uint idx, bool debtorConfirmed) public isParent {
    (f, s) = debtIndices(p1, p2);
    debts[f][s][idx].debtorConfirmed = debtorConfirmed;
  }
  function dSetCreditorConfirmed(bytes32 p1, bytes32 p2, uint idx, bool creditorConfirmed) public isParent {
    (f, s) = debtIndices(p1, p2);
    debts[f][s][idx].creditorConfirmed = creditorConfirmed;
  }
  function dSetDesc(bytes32 p1, bytes32 p2, uint idx, bytes32 desc) public isParent {
    (f, s) = debtIndices(p1, p2);
    debts[f][s][idx].desc = desc;
  }

}
