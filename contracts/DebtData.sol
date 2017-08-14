pragma solidity ^0.4.11;

contract DebtData {
  address admin;
  address admin2;
  address fluxContract;

  /*  Debt  */
  mapping ( bytes32 => bool ) currencyCodes;
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
  mapping ( bytes32 => mapping ( bytes32 => Debt[] )) debts;
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
  function debtIndices(bytes32 p1, bytes32 p2) constant returns (bytes32, bytes32) {
    if ( debts[p1][p2].length > 0 )
      return (p1, p2);
    else
      return (p2, p1);
  }

  /* Flux Getters   */
  function numDebts(bytes32 p1, bytes32 p2) constant returns (uint) {
    (f, s) = debtIndices(p1, p2);
    return debts[f][s].length;
  }
  function currencyValid(bytes32 currencyCode) constant returns (bool) {
    return currencyCodes[currencyCode];
  }
  function getNextDebtId() constant returns (uint) {
    return nextDebtId;
  }

  function dUcac(bytes32 p1, bytes32 p2, uint idx) constant returns (address) {
    (f, s) = debtIndices(p1, p2);
    return debts[f][s][idx].ucac;
  }

  function dId(bytes32 p1, bytes32 p2, uint idx) constant returns (uint) {
    (f, s) = debtIndices(p1, p2);
    return debts[f][s][idx].id;
  }
  function dTimestamp (bytes32 p1, bytes32 p2, uint idx) constant returns (uint) {
    (f, s) = debtIndices(p1, p2);
    return debts[f][s][idx].timestamp;
  }
  function dAmount(bytes32 p1, bytes32 p2, uint idx) constant returns (int) {
    (f, s) = debtIndices(p1, p2);
    return debts[f][s][idx].amount;
  }
  function dCurrencyCode(bytes32 p1, bytes32 p2, uint idx) constant returns (bytes32) {
    (f, s) = debtIndices(p1, p2);
    return debts[f][s][idx].currencyCode;
  }
  function dDebtorId(bytes32 p1, bytes32 p2, uint idx) constant returns (bytes32) {
    (f, s) = debtIndices(p1, p2);
    return debts[f][s][idx].debtorId;
  }
  function dCreditorId(bytes32 p1, bytes32 p2, uint idx) constant returns (bytes32) {
    (f, s) = debtIndices(p1, p2);
    return debts[f][s][idx].creditorId;
  }
  function dIsPending(bytes32 p1, bytes32 p2, uint idx) constant returns (bool) {
    (f, s) = debtIndices(p1, p2);
    return debts[f][s][idx].isPending;
  }
  function dIsRejected(bytes32 p1, bytes32 p2, uint idx) constant returns (bool) {
    (f, s) = debtIndices(p1, p2);
    return debts[f][s][idx].isRejected;
  }
  function dDebtorConfirmed (bytes32 p1, bytes32 p2, uint idx) constant returns (bool) {
    (f, s) = debtIndices(p1, p2);
    return debts[f][s][idx].debtorConfirmed;
  }
  function dCreditorConfirmed (bytes32 p1, bytes32 p2, uint idx) constant returns (bool) {
    (f, s) = debtIndices(p1, p2);
    return debts[f][s][idx].creditorConfirmed;
  }
  function dDesc(bytes32 p1, bytes32 p2, uint idx) constant returns (bytes32) {
    (f, s) = debtIndices(p1, p2);
    return debts[f][s][idx].desc;
  }

  /* Flux Setters   */
  function dSetCurrencyCode(bytes32 currencyCode, bool val) public isParent {
    currencyCodes[currencyCode] = val;
  }
  function dSetNextDebtId(uint newId) public isParent {
    nextDebtId = newId;
  }
  function pushBlankDebt(bytes32 p1, bytes32 p2) public isParent {
    (f, s) = debtIndices(p1, p2);
    debts[f][s].push(blankDebt);
  }

  function dSetUcac(bytes32 p1, bytes32 p2, uint idx, address ucac) public isParent {
    (f, s) = debtIndices(p1, p2);
    debts[f][s][idx].ucac = ucac;
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
