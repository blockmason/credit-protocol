# Credit Protocol Smart Contracts

Ethereum Smart Contracts for the Debt Protocol dApp that faciliates debt tracking between any two parties.

## How the Credit Protocol works

## `CreditProtocol.Sol`

### What is logged

## `Stake.sol`

`Stake.sol` is responsible for registering UCACs and rate-limiting their issuances of credit based on how many BCPT have been staked for that particular UCAC.

### Transaction Levels and their decay

## UCAC Contract

A UCAC contract, the most basic of which can be seen [here](contracts/BasicUCAC.sol), is required at minimum to implement a single fuction with the following signature:

```
function allowTransaction(address creditor, address debtor, uint256 amount) public returns (bool)
```

This function is called by `CreditProtocol.sol` in the function `issueCredit`. By returning `true`, `allowTransaction` approves the issuance of credit, by returning `false`, `allowTransaction` can block the issuance of credit. Typically, a UCAC will use its power to appove transactions to make sure the transactions satisfy certain requirements. For example, a UCAC may want to block a transaction which involves any party who is two heavily in debt.
