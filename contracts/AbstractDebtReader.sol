pragma solidity ^0.4.11;

contract AbstractDebtReader {
  function pendingDebts(address ucac, bytes32 fId) constant returns (uint[] debtIds, bytes32[] confirmerIds, bytes32[] currency, int[] amounts, bytes32[] descs, bytes32[] debtors, bytes32[] creditors);
  function pendingDebtTimestamps(address ucac, bytes32 fId) constant returns (uint[] timestamps);
  function confirmedDebtBalances(address ucac, bytes32 fId) constant returns (bytes32[] currency, int[] amounts, bytes32[] counterpartyIds, uint[] totalDebts, uint[] mostRecent);
  function confirmedDebts(address ucac, bytes32 p1, bytes32 p2) constant returns (bytes32[] currency2, int[] amounts2, bytes32[] descs2, bytes32[] debtors2, bytes32[] creditors2, uint[] timestamps2);
}
