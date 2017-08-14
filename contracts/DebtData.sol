pragma solidity ^0.4.11;

contract DebtData {
  address admin;
  address admin2;
  address fluxContract;

  /*  Debt  */
  uint nextDebtId;
  struct Debt {
    address ucac;  //the ucac that authorized creation of this debt
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
  mapping ( address => mapping ( bytes32 => mapping ( bytes32 => Debt[] ))) debts;
  Debt blankDebt; //Used to push onto debts

  /*  modifiers  */
  modifier isAdmin() {
    if ( (admin != msg.sender) && (admin2 != msg.sender)) revert();
    _;
  }

  modifier isParent() {
    if ( (msg.sender != fluxContract) ) revert();
    _;
  }

  /* main functions */
  function DebtData(address _admin2) {
    admin = msg.sender;
    admin2 = _admin2;
  }

  function setFluxContract(address _fluxContract) public isAdmin {
    fluxContract = _fluxContract;
  }

  function getFluxContract() constant returns (address) {
    return fluxContract;
  }

  function getAdmins() constant returns (address, address) {
    return (admin, admin2);
  }

  /* Flux helpers */
  bytes32 f;
  bytes32 s;
  function debtIndices(address ucac, bytes32 p1, bytes32 p2) constant returns (bytes32, bytes32) {
    if ( debts[ucac][p1][p2].length > 0 )
      return (p1, p2);
    else
      return (p2, p1);
  }

  /* Flux Getters   */
  function numDebts(address ucac, bytes32 p1, bytes32 p2) constant returns (uint) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s].length;
  }
  function getNextDebtId() constant returns (uint) {
    return nextDebtId;
  }

  function dUcac(address ucac, bytes32 p1, bytes32 p2, uint idx) constant returns (address) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s][idx].ucac;
  }

  function dId(address ucac, bytes32 p1, bytes32 p2, uint idx) constant returns (uint) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s][idx].id;
  }
  function dTimestamp (address ucac, bytes32 p1, bytes32 p2, uint idx) constant returns (uint) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s][idx].timestamp;
  }
  function dAmount(address ucac, bytes32 p1, bytes32 p2, uint idx) constant returns (int) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s][idx].amount;
  }
  function dCurrencyCode(address ucac, bytes32 p1, bytes32 p2, uint idx) constant returns (bytes32) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s][idx].currencyCode;
  }
  function dDebtorId(address ucac, bytes32 p1, bytes32 p2, uint idx) constant returns (bytes32) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s][idx].debtorId;
  }
  function dCreditorId(address ucac, bytes32 p1, bytes32 p2, uint idx) constant returns (bytes32) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s][idx].creditorId;
  }
  function dIsPending(address ucac, bytes32 p1, bytes32 p2, uint idx) constant returns (bool) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s][idx].isPending;
  }
  function dIsRejected(address ucac, bytes32 p1, bytes32 p2, uint idx) constant returns (bool) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s][idx].isRejected;
  }
  function dDebtorConfirmed (address ucac, bytes32 p1, bytes32 p2, uint idx) constant returns (bool) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s][idx].debtorConfirmed;
  }
  function dCreditorConfirmed (address ucac, bytes32 p1, bytes32 p2, uint idx) constant returns (bool) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s][idx].creditorConfirmed;
  }
  function dDesc(address ucac, bytes32 p1, bytes32 p2, uint idx) constant returns (bytes32) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s][idx].desc;
  }

  /* Flux Setters   */
  function dSetNextDebtId(uint newId) public isParent {
    nextDebtId = newId;
  }
  function pushBlankDebt(address ucac, bytes32 p1, bytes32 p2) public isParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s].push(blankDebt);
  }

  function dSetUcac(address ucac, bytes32 p1, bytes32 p2, uint idx, address ucac) public isParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s][idx].ucac = ucac;
  }

  function dSetId(address ucac, bytes32 p1, bytes32 p2, uint idx, uint id) public isParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s][idx].id = id;
  }
  function dSetTimestamp(address ucac, bytes32 p1, bytes32 p2, uint idx, uint timestamp) public isParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s][idx].timestamp = timestamp;
  }
  function dSetAmount(address ucac, bytes32 p1, bytes32 p2, uint idx, int amount) public isParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s][idx].amount = amount;
  }
  function dSetCurrencyCode(address ucac, bytes32 p1, bytes32 p2, uint idx, bytes32 currencyCode) public isParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s][idx].currencyCode = currencyCode;
  }
  function dSetDebtorId(address ucac, bytes32 p1, bytes32 p2, uint idx, bytes32 debtorId) public isParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s][idx].debtorId = debtorId;
  }
  function dSetCreditorId(address ucac, bytes32 p1, bytes32 p2, uint idx, bytes32 creditorId) public isParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s][idx].creditorId = creditorId;
  }
  function dSetIsPending(address ucac, bytes32 p1, bytes32 p2, uint idx, bool isPending) public isParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s][idx].isPending = isPending;
  }
  function dSetIsRejected(address ucac, bytes32 p1, bytes32 p2, uint idx, bool isRejected) public isParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s][idx].isRejected = isRejected;
  }
  function dSetDebtorConfirmed(address ucac, bytes32 p1, bytes32 p2, uint idx, bool debtorConfirmed) public isParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s][idx].debtorConfirmed = debtorConfirmed;
  }
  function dSetCreditorConfirmed(address ucac, bytes32 p1, bytes32 p2, uint idx, bool creditorConfirmed) public isParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s][idx].creditorConfirmed = creditorConfirmed;
  }
  function dSetDesc(address ucac, bytes32 p1, bytes32 p2, uint idx, bytes32 desc) public isParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s][idx].desc = desc;
  }
}
