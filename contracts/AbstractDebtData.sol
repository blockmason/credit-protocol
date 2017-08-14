pragma solidity ^0.4.11;

contract AbstractDebtData {

  /* main functions */
  function DebtData(address _admin2);

  function setFluxContract(address _fluxContract);
  function getFluxContract() constant returns (address fluxContract);
  function getAdmins() constant returns (address admin, address admin2);

  /* Debt helpers */
  function debtIndices(address ucac, bytes32 p1, bytes32 p2) constant returns (bytes32 first, bytes32 second);

  /* Debt Getters   */
  function numDebts(address ucac, bytes32 p1, bytes32 p2) constant returns (uint numDebts);
  function getNextDebtId() constant returns (uint);
  function dId(address ucac, bytes32 p1, bytes32 p2, uint idx) constant returns (uint id);
  function dTimestamp (address ucac, bytes32 p1, bytes32 p2, uint idx) constant returns (uint timestamp);
  function dAmount(address ucac, bytes32 p1, bytes32 p2, uint idx) constant returns (int amount);
  function dCurrencyCode(address ucac, bytes32 p1, bytes32 p2, uint idx) constant returns (bytes32 currencyCode);
  function dDebtorId(address ucac, bytes32 p1, bytes32 p2, uint idx) constant returns (bytes32 debtorId);
  function dCreditorId(address ucac, bytes32 p1, bytes32 p2, uint idx) constant returns (bytes32 creditorId);
  function dIsPending(address ucac, bytes32 p1, bytes32 p2, uint idx) constant returns (bool isPending);
  function dIsRejected(address ucac, bytes32 p1, bytes32 p2, uint idx) constant returns (bool isRejected);
  function dDebtorConfirmed (address ucac, bytes32 p1, bytes32 p2, uint idx) constant returns (bool debtorConfirmed);
  function dCreditorConfirmed (address ucac, bytes32 p1, bytes32 p2, uint idx) constant returns (bool creditorConfirmed);
  function dDesc(address ucac, bytes32 p1, bytes32 p2, uint idx) constant returns (bytes32 desc);

  /* Debt Setters   */
  function dSetNextDebtId(uint newId);
  function pushBlankDebt(address ucac, bytes32 p1, bytes32 p2);
  function dSetId(address ucac, bytes32 p1, bytes32 p2, uint idx, uint id);
  function dSetTimestamp(address ucac, bytes32 p1, bytes32 p2, uint idx, uint timestamp);
  function dSetAmount(address ucac, bytes32 p1, bytes32 p2, uint idx, int amount);
  function dSetCurrencyCode(address ucac, bytes32 p1, bytes32 p2, uint idx, bytes32 currencyCode);
  function dSetDebtorId(address ucac, bytes32 p1, bytes32 p2, uint idx, bytes32 debtorId);
  function dSetCreditorId(address ucac, bytes32 p1, bytes32 p2, uint idx, bytes32 creditorId);
  function dSetIsPending(address ucac, bytes32 p1, bytes32 p2, uint idx, bool isPending);
  function dSetIsRejected(address ucac, bytes32 p1, bytes32 p2, uint idx, bool isRejected);
  function dSetDebtorConfirmed(address ucac, bytes32 p1, bytes32 p2, uint idx, bool debtorConfirmed);
  function dSetCreditorConfirmed(address ucac, bytes32 p1, bytes32 p2, uint idx, bool creditorConfirmed);
  function dSetDesc(address ucac, bytes32 p1, bytes32 p2, uint idx, bytes32 desc);

}
