# Introduction

The Credit Protocol is a powerful blockchain solution to storing credits and debts on the blockchain.  This doc will help walk you through interacting with and integrating the Credit Protocol into your UCAC (use case authority contract) which will be built atop the protocol.  All docs here refer to the most updated version of the protocol at https://github.com/blockmason/credit-protocol

# Credit Protocol Smart Contracts

Ethereum Smart Contracts for the Debt Protocol dApp that faciliates debt
tracking between any two parties.

## Contract Addresses
* Stake.sol ```0xfA5B488799ae2514757Ba0a0a4DA7AB764e0f8d2```
* CreditProtocol.sol ```0x9aa6596444eefaf28fda17be861adfac289c773f```

## How the Credit Protocol works

### CreditProtocol.sol

`CreditProtocol.sol` is mainly responsible for logging issuances of credit to
the Ethereum blockchain. Credit can be issued under the following conditions:

- Both parties in a debt relationship cryptographically sign the elements of
a credit record

- The UCAC contract which is referenced in the credit record acknowledges that
the credit record is valid for its particular use case (see section
[UCAC contract](#ucac-contract) for more information)

- Users of the Credit Protocal have staked the UCAC contract with enough BCPT
to handle the issuance of credit (see section [Stake.sol](#stakesol) for more information)

In addition to logging issuances of credit, `CreditProtocol.sol` maintains
a mapping of the credit balances of all users. A unique user balance is
maintained for every `(UCAC, user)` pair.

#### What is logged

```
event IssueCredit(bytes32 indexed ucac, address indexed creditor, address indexed debtor, uint256 amount);
```

### Stake.sol

`Stake.sol` is responsible for registering UCACs and rate-limiting their
issuances of credit based on how many BCPT they've been staked with. The
contract maintains a mapping of ucacIds to ucac information records; and is
primary source of information on registerd UCACs.

#### UCAC information stored by `Stake.sol`

- UCAC contract address
- total number of tokens staked
- "txLevel" which is a measure of how many credit transactions have been
performed in the recent past. This is used by `Stake.sol` to rate limit
transactions based on the number of tokens staked to a particular UCAC
- timestamp of the last UCAC transaction
- denomination of credit issued in the UCAC

### UCAC Contract

A UCAC contract, the most basic of which can be seen
[here](contracts/BasicUCAC.sol), is required to implement a single fuction with
the following signature:

```
function allowTransaction(address creditor, address debtor, uint256 amount) public returns (bool)
```

`allowTransaction` is called by `CreditProtocol.sol` in its function `issueCredit`.
By returning `true`, `allowTransaction` approves the issuance of credit; by
returning `false`, `allowTransaction` can block the issuance of credit.
Typically, a UCAC will use its power to appove transactions to make sure the
transactions satisfy certain requirements. For example, a UCAC may want to
block a transaction which involves any party who is too heavily in debt.

## Testing

To run all `testrpc` tests, execute `./runtest.sh`. To run only a specific
test, execute `./runtest.sh [path-to-test-file]`.
