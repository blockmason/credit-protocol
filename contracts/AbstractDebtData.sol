pragma solidity ^0.4.11;

contract AbstractDebtData {

  /* main functions */
  function DebtData(address _admin2);

  function setFluxContract(address _fluxContract);
  function getFluxContract() constant returns (address fluxContract);
  function getAdmins() constant returns (address admin, address admin2);

  /* Flux helpers */
  function debtIndices(bytes32 p1, bytes32 p2) constant returns (bytes32 first, bytes32 second);

  /* Flux Getters   */
  function numDebts(bytes32 p1, bytes32 p2) constant returns (uint numDebts);
  function currencyValid(bytes32 currencyCode) constant returns (bool);
  function getNextDebtId() constant returns (uint);
  function dUcac(bytes32 p1, bytes32 p2, uint idx) constant returns (address);
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

  /* Flux Setters   */
  function dSetCurrencyCode(bytes32 currencyCode, bool val);
  function dSetNextDebtId(uint newId);
  function pushBlankDebt(bytes32 p1, bytes32 p2);
  function dSetUcac(bytes32 p1, bytes32 p2, uint idx, address ucac);
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
