pragma solidity ^0.4.11;

import "./Parentable.sol";
import "./SafeMath.sol";

contract DebtData is Parentable {
  using SafeMath for uint256;

  /*  Debt  */
  //  mapping ( bytes32 => bool ) public currencyCodes;
  struct Debt {
    bytes32 ucac;  //the ucac that authorized creation of this debt
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
  mapping ( bytes32 => mapping (bytes32 => mapping ( bytes32 => Debt[] ))) public debts;
  uint public nextDebtId;
  Debt private blankDebt; //Used to push onto debts


  /* Flux helpers */
  bytes32 f;
  bytes32 s;
  function debtIndices(bytes32 ucac, bytes32 p1, bytes32 p2) private constant returns (bytes32, bytes32) {
    if ( debts[ucac][p1][p2].length > 0 )
      return (p1, p2);
    else
      return (p2, p1);
  }

  /* Flux Getters   */
  function numDebts(bytes32 ucac, bytes32 p1, bytes32 p2) public constant returns (uint) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s].length;
  }

  function getNextDebtId() public constant returns (uint) {
    return nextDebtId;
  }

  function dUcac(bytes32 ucac, bytes32 p1, bytes32 p2, uint idx) public constant returns (bytes32) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s][idx].ucac;
  }

  function dId(bytes32 ucac, bytes32 p1, bytes32 p2, uint idx) public constant returns (uint) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s][idx].id;
  }
  function dTimestamp (bytes32 ucac, bytes32 p1, bytes32 p2, uint idx) public constant returns (uint) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s][idx].timestamp;
  }
  function dAmount(bytes32 ucac, bytes32 p1, bytes32 p2, uint idx) public constant returns (int) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s][idx].amount;
  }
  function dCurrencyCode(bytes32 ucac, bytes32 p1, bytes32 p2, uint idx) public constant returns (bytes32) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s][idx].currencyCode;
  }
  function dDebtorId(bytes32 ucac, bytes32 p1, bytes32 p2, uint idx) public constant returns (bytes32) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s][idx].debtorId;
  }
  function dCreditorId(bytes32 ucac, bytes32 p1, bytes32 p2, uint idx) public constant returns (bytes32) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s][idx].creditorId;
  }
  function dIsPending(bytes32 ucac, bytes32 p1, bytes32 p2, uint idx) public constant returns (bool) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s][idx].isPending;
  }
  function dIsRejected(bytes32 ucac, bytes32 p1, bytes32 p2, uint idx) public constant returns (bool) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s][idx].isRejected;
  }
  function dDebtorConfirmed (bytes32 ucac, bytes32 p1, bytes32 p2, uint idx) public constant returns (bool) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s][idx].debtorConfirmed;
  }
  function dCreditorConfirmed (bytes32 ucac, bytes32 p1, bytes32 p2, uint idx) public constant returns (bool) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s][idx].creditorConfirmed;
  }
  function dDesc(bytes32 ucac, bytes32 p1, bytes32 p2, uint idx) public constant returns (bytes32) {
    (f, s) = debtIndices(ucac, p1, p2);
    return debts[ucac][f][s][idx].desc;
  }

  /* Flux Setters   */
  function incrementDebtId() public onlyParent {
    nextDebtId = nextDebtId.add(1);
  }

  function pushBlankDebt(bytes32 ucac, bytes32 p1, bytes32 p2) public onlyParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s].push(blankDebt);
  }

  function dSetUcac(bytes32 ucac, bytes32 p1, bytes32 p2, uint idx) public onlyParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s][idx].ucac = ucac;
  }

  function dSetId(bytes32 ucac, bytes32 p1, bytes32 p2, uint idx, uint id) public onlyParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s][idx].id = id;
  }
  function dSetTimestamp(bytes32 ucac, bytes32 p1, bytes32 p2, uint idx, uint timestamp) public onlyParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s][idx].timestamp = timestamp;
  }
  function dSetAmount(bytes32 ucac, bytes32 p1, bytes32 p2, uint idx, int amount) public onlyParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s][idx].amount = amount;
  }
  function dSetCurrencyCode(bytes32 ucac, bytes32 p1, bytes32 p2, uint idx, bytes32 currencyCode) public onlyParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s][idx].currencyCode = currencyCode;
  }
  function dSetDebtorId(bytes32 ucac, bytes32 p1, bytes32 p2, uint idx, bytes32 debtorId) public onlyParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s][idx].debtorId = debtorId;
  }
  function dSetCreditorId(bytes32 ucac, bytes32 p1, bytes32 p2, uint idx, bytes32 creditorId) public onlyParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s][idx].creditorId = creditorId;
  }
  function dSetIsPending(bytes32 ucac, bytes32 p1, bytes32 p2, uint idx, bool isPending) public onlyParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s][idx].isPending = isPending;
  }
  function dSetIsRejected(bytes32 ucac, bytes32 p1, bytes32 p2, uint idx, bool isRejected) public onlyParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s][idx].isRejected = isRejected;
  }
  function dSetDebtorConfirmed(bytes32 ucac, bytes32 p1, bytes32 p2, uint idx, bool debtorConfirmed) public onlyParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s][idx].debtorConfirmed = debtorConfirmed;
  }
  function dSetCreditorConfirmed(bytes32 ucac, bytes32 p1, bytes32 p2, uint idx, bool creditorConfirmed) public onlyParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s][idx].creditorConfirmed = creditorConfirmed;
  }
  function dSetDesc(bytes32 ucac, bytes32 p1, bytes32 p2, uint idx, bytes32 desc) public onlyParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s][idx].desc = desc;
  }
}
