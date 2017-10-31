# Credit Protocol Smart Contracts

Ethereum Smart Contracts for the Debt Protocol dApp that faciliates debt
tracking between any two parties.

## Contract Address
* CreditProtocol.sol `0x694a92520101d8f78a7aba2578380628565e3621`

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

#### TxDecay Calculation

Only one action can increase a UCAC's transaction level `txLevel`, i.e. issuing
credit successfully via a call to the CreditProtocol's `issueCredit` function.
The logic for increasing a UCAC's txLevel is contained in the `executeUcacTx`
function.

```
uint256 txLevelBeforeCurrentTx = currentTxLevel(_ucacId);
uint256 txLevelAfterCurrentTx = txLevelBeforeCurrentTx + 10 ** 27 / txPerGigaTokenPerHour;
```

The owner of the CreditProcol contract is able to set the value of
`txPerGigaTorkenPerHour`. This value determines the amount which every
transaction increases the txLevel, which, as shown above, is equal to
`10 ** 27 / txPerGigaTokenPerHour`.

Two actions can change the rate at which txLevel decays, specifically,
unstaking tokens from a UCAC and staking tokens to a UCAC. The txDecay rate is
independent of the value of `txPerGigaTokenPerHour`. The value of
`currentDecay` is calculated precisely to ensure that over the course of one
hour, a txLevel of `ucacs[_ucacId].totalStakedTokens` would decay to zero in
one hour (3600 seconds).

```
function currentTxLevel(bytes32 _ucacId) public constant returns (uint256) {
    uint256 totalStaked = ucacs[_ucacId].totalStakedTokens;
    uint256 currentDecay = totalStaked / 3600 * (now - ucacs[_ucacId].lastTxTimestamp);
    uint256 adjustedTxLevel = ucacs[_ucacId].txLevel < currentDecay ? 0 : ucacs[_ucacId].txLevel - currentDecay;
    return adjustedTxLevel;
}
```

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
