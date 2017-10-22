# Credit Protocol Smart Contracts

Ethereum Smart Contracts for the Debt Protocol dApp that faciliates debt
tracking between any two parties.

## Contract Addresses
* Stake.sol ```0x57d78a7969bbf8d2d7725c215e388958860730cd```
* CreditProtocol.sol ```0xbd603d1129cb444ab8dedc979328c0183563ee8d```

## How the Credit Protocol works

### CreditProtocol.sol

`CreditProtocol.sol` serves two principle functions

- creating and staking new UCACs
- logging issuances of credit to the Ethereum blockchain.

Credit can be issued under the following conditions:

- Both parties in a debt relationship cryptographically sign the elements of
a credit record

- The UCAC contract which is referenced in the credit record acknowledges that
the credit record is valid for its particular use case (see section
[UCAC contract](#ucac-contract) for more information)

- Users of the Credit Protocal have staked the UCAC contract with enough BCPT
to handle the issuance of credit (see section [Staking](#staking) for more information)

In addition to logging issuances of credit, `CreditProtocol.sol` maintains
a mapping of the credit balances of all users. A unique user balance is
maintained for every `(UCAC, user)` pair.

#### What is logged

```
event IssueCredit(bytes32 indexed ucac, address indexed creditor, address indexed debtor, uint256 amount);
```

#### Staking

As mentioned above, `CreditProtocol.sol` is responsible for registering UCACs
and rate-limiting their issuances of credit based on how many BCPT they've been
staked with. The contract maintains a mapping of ucacIds to ucac information
records; and is primary source of information on registerd UCACs.

UCAC information stored by `CreditProtocol.sol`:

- UCAC contract address
- total number of tokens staked
- "txLevel" which is a measure of how many credit transactions have been
performed in the recent past. This is used by CreditProtocol to rate limit
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
