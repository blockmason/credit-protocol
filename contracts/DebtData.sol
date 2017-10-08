pragma solidity ^0.4.15;

import "blockmason-solidity-libs/contracts/Parentable.sol";
import "blockmason-solidity-libs/contracts/Helpers.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";

contract DebtData is Parentable {
  using SafeMath for uint256;

  /*  Debt  */
  //  mapping ( bytes32 => bool ) public currencyCodes;
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

  struct DebtIndex {
    bytes32 ucac;
    bytes32 f;
    bytes32 s;
    uint index;
  }

  mapping ( bytes32 => mapping (bytes32 => mapping ( bytes32 => Debt[] ))) public debts;
  mapping ( uint => DebtIndex ) public debtsByDebtId;
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
  function dGenerateId(bytes32 ucac, bytes32 p1, bytes32 p2, uint idx) public onlyParent {
    (f, s) = debtIndices(ucac, p1, p2);
    debts[ucac][f][s][idx].id = nextDebtId;
    nextDebtId = nextDebtId.add(1);
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

  /* batch functions */

  function debtFullIndex(uint _debtId) public constant returns (bytes32, bytes32, bytes32, uint) {
    return (debtsByDebtId[_debtId].ucac, debtsByDebtId[_debtId].f, debtsByDebtId[_debtId].s, debtsByDebtId[_debtId].index);
  }

  function debtIndex(uint _debtId) public constant returns (uint) {
    return debtsByDebtId[_debtId].index;
  }

  /**

   **/
  function initDebt(bytes32 ucac, bytes32 debtorId, bytes32 creditorId, bytes32 currencyCode, int amount, bytes32 desc, bool debtorConfirmed, bool creditorConfirmed) public onlyParent {
    (f, s) = debtIndices(ucac, debtorId, creditorId);
    debts[ucac][f][s].push(blankDebt);
    uint index = (debts[ucac][f][s].length).sub(1);

    debtsByDebtId[nextDebtId].ucac = ucac;
    debtsByDebtId[nextDebtId].f = f;
    debtsByDebtId[nextDebtId].s = s;
    debtsByDebtId[nextDebtId].index = index;

    debts[ucac][f][s][index].id = nextDebtId;
    debts[ucac][f][s][index].timestamp = now;
    debts[ucac][f][s][index].amount = amount;
    debts[ucac][f][s][index].currencyCode = currencyCode;
    debts[ucac][f][s][index].debtorId = debtorId;
    debts[ucac][f][s][index].creditorId = creditorId;
    debts[ucac][f][s][index].isPending = true;
    debts[ucac][f][s][index].desc = desc;
    if(debtorConfirmed)
      debts[ucac][f][s][index].debtorConfirmed = true;
    if(creditorConfirmed)
      debts[ucac][f][s][index].creditorConfirmed = true;

    nextDebtId = nextDebtId.add(1);
  }

  function confirmDebt(bytes32 ucac, bytes32 myId, bytes32 friendId, uint debtId) public onlyParent {
    (f, s) = debtIndices(ucac, myId, friendId);
    uint index = debtsByDebtId[debtId].index;
    bool debtorSameAsMyId = Helpers.compare(myId, debts[ucac][f][s][index].debtorId) == 0;
    bool creditorSameAsMyId = Helpers.compare(myId, debts[ucac][f][s][index].creditorId) == 0;

    if(debtorSameAsMyId && !debts[ucac][f][s][index].debtorConfirmed && debts[ucac][f][s][index].creditorConfirmed) {
      debts[ucac][f][s][index].debtorConfirmed = true;
      debts[ucac][f][s][index].isPending = false;
    }
    else if(creditorSameAsMyId && !debts[ucac][f][s][index].creditorConfirmed && debts[ucac][f][s][index].debtorConfirmed) {
      debts[ucac][f][s][index].creditorConfirmed = true;
      debts[ucac][f][s][index].isPending = false;
    }
    else
      revert();
  }

  function rejectDebt(bytes32 ucac, bytes32 rejector, bytes32 rejectee, uint debtId) public onlyParent {
    (f, s) = debtIndices(ucac, rejector, rejectee);
    uint index = debtsByDebtId[debtId].index;

    debts[ucac][f][s][index].isPending = false;
    debts[ucac][f][s][index].isRejected = true;
    debts[ucac][f][s][index].debtorConfirmed = false;
    debts[ucac][f][s][index].creditorConfirmed = false;
  }

}
