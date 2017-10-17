# Credit Protocol Smart Contracts

Ethereum Smart Contracts for the Debt Protocol dApp that faciliates debt tracking between any two parties.

## How the Credit Protocol works

## `CreditProtocol.sol`

`CreditProtocol.sol` is mainly responsible for logging issuances of credit to the Ethereum blockchain. Credit can be issued under the following conditions:

- Both parties in a debt relationship cryptographically sign the elements of a credit record with the private key that corresponds to thier public address
- The UCAC contract which is referenced in the credit record acknowledges that the credit record is valid for the particular use case (see section [UCAC Contract] for more information)
- Users of the Credit Protocal have staked the UCAC contract with enough BCPT to handle the issuance of credit (see section [Stake.sol] for more information)

In addition to logging issuances of credit, `CreditProtocol.sol` maintains a mapping of nonces for every pair of users that have ever entered into a credit relationship, and a mapping of balances for every user per UCAC.

### What is logged

```
event IssueCredit(bytes32 indexed ucac, address indexed creditor, address indexed debtor, uint256 amount);
```

## `Stake.sol`

`Stake.sol` is responsible for registering UCACs and rate-limiting their issuances of credit based on how many BCPT have been staked for that particular UCAC. It maintains a mapping of `ucacId -> Ucac struct` and is the main resources of users of the Credit Protocol to .

Users stake tokens in order to buy ...

### UCAC information stored by `Stake.sol`

- UCAC contract address
- total number of tokens staked
- "txLevel" which is a measure of how many credit transactions have been performed in the recent past. This is used by `Stake.sol` to rate limit transactions based on the number of tokens staked to a particular UCAC
- timestamp of the last UCAC transaction
- denomination of credit issued in the UCAC

### Transaction Levels and their decay

TODO

## UCAC Contract

A UCAC contract, the most basic of which can be seen [here](contracts/BasicUCAC.sol), is required to implement a single fuction with the following signature:

```
function allowTransaction(address creditor, address debtor, uint256 amount) public returns (bool)
```

This function is called by `CreditProtocol.sol` in the function `issueCredit`. By returning `true`, `allowTransaction` approves the issuance of credit, by returning `false`, `allowTransaction` can block the issuance of credit. Typically, a UCAC will use its power to appove transactions to make sure the transactions satisfy certain requirements. For example, a UCAC may want to block a transaction which involves any party who is too heavily in debt.
