pragma solidity ^0.4.24;

import "tce-contracts/contracts/CPToken.sol";
import "./BasicUCAC.sol";

/**
 * The Credit Protocol provides a standardized, token-regulated, and
 * extensible way to record credit transactions on the Ethereum blockchain.
 *
 * Here's how it works:
 *
 * The Credit Protocol requires a **use case** to be registered. A use case
 * is represented as a "use case authority contract", or "UCAC" for short,
 * which is responsible for making the decision whether a credit transaction
 * is allowed. The simplest possible UCAC would just allow all transactions,
 * but the Credit Protocol is designed to allow for more sophisticated use
 * cases to make an informed, data-driven decision.
 *
 * A developer writes and deploys a *use case* smart contract. Then, the
 * developer needs to *register* that contract with the Credit Protocol.
 * To register the contract, it needs to be *staked* with Credit Protocol
 * tokens (BCPTs). The minimum number of tokens required is indicated by
 * the `tokensToOwnUcac` variable on the Credit Protocol contract. To
 * register the contract, the developer would first call `#approve` on the
 * BCPT contract with the exact number of tokens being used to stake the
 * UCAC, then call `#createAndStakeUcac` on the Credit Protocol contract
 * specifying the UCAC address, that number of tokens, and an optional
 * denomination/currency identifier.
 *
 * Once a UCAC is registered and staked, the Credit Protocol allows
 * transactions to occur using that UCAC. This occurs via the `#issueCredit`
 * function, and requires signatures from both parties involved in the transaction
 * as well as the details of the transaction itself. When this function is
 * called, once all validations have completed, the UCAC's `#allowTransaction`
 * function is called. Only if this returns `true` does the Credit Protocol
 * record the transaction -- otherwise it fails the transaction and does not
 * log it.
 *
 * Multiple stakeholders can stake or unstake tokens in any UCAC, using the
 * `#stakeTokens` and `#unstakeTokens` functions, respectively. If a UCAC's
 * staked tokens falls below the minimum number of tokens required, then
 * transactions can no longer take place for that UCAC until adequate tokens
 * are staked.
 *
 * The bandwidth allocated by the Credit Protocol for processing transactions
 * directly correlates to the number of tokens staked in the associated UCAC.
 * The more tokens staked, the more transactions that may be processed per hour.
 * The exact rate is specified in `#txPerGigaTokenPerHour`, and the current
 * transaction spend for a UCAC can be examined via the `#ucacs` struct, in the
 * `#txLevel` field for that UCAC.
 */
contract CreditProtocol {
    struct Ucac {
        address ucacContractAddr;
        uint256 totalStakedTokens;
        uint256 txLevel;
        uint256 lastTxTimestamp;
        bytes32 denomination;
    }

    /**
     * The token contract used to fund this contract.
     */
    CPToken public token;

    /**
     * The rate at which staked tokens affect transaction bandwidth.
     */
    uint256 public txPerGigaTokenPerHour;

    /**
     * The number of tokens required to register a new use case authority
     * contract (UCAC) or to allow transactions in a UCAC to be processed.
     */
    uint256 public tokensToOwnUcac;

    /**
     * Details of a given use case authority contract (UCAC).
     */
    mapping (address => Ucac) public ucacs;

    /**
     * A mapping of stakeholders for a use case authority contract (UCAC).
     * The key of the first mapping is the UCAC address.
     * The key of the second mapping is the stakeholder address.
     * The value of the second mapping is the number of tokens staked.
     */
    mapping (address => mapping (address => uint256)) public stakedTokensMap;

    /**
     * A mapping of nonces between pairs of accounts conducting transactions
     * in the Credit Protocol.
     * The key of the first mapping is the account address with the lowest numeric value.
     * The key of the second mapping is the other account address.
     * The value of the second mapping is the current nonce between the account pair.
     */
    mapping (address => mapping (address => uint256)) public nonces;

    /**
     * A mapping of account balances for each use case authority contract (UCAC).
     * The key of the first mapping is the UCAC address.
     * The key of the second mapping is the account address.
     * The value of the second mapping is the balance, expressed in credits.
     * A positive balance means that the account is owed more than it owes.
     * A negative balance means that the account owes more than it is owed.
     * A zero balance means the account neither owes nor is owed.
     * Important Note: An account's balance *is not* indicative of whether there
     * are outstanding credits or debts between that account and others. For a
     * full, itemized transaction log, query on the `IssueCredit` event.
     */
    mapping (address => mapping (address => int256)) public balances;

    /**
     * This event is emitted whenever credit is successfully issued.
     */
    event IssueCredit(address indexed ucac, address indexed creditor, address indexed debtor, uint256 amount, uint256 nonce, bytes32 memo);

    /**
     * This event is emitted whenever a use case authority contract (UCAC)
     * is successfully registered with the Credit Protocol.
     */
    event UcacCreation(address indexed ucac, bytes32 denomination);

    /**
     * This event is emitted whenever ownership of this contract has been
     * successfully transferred.
     */
    event OwnershipTransferred(address oldOwner, address newOwner);

    uint256 transactionCost;
    bytes prefix = "\x19Ethereum Signed Message:\n32";
    address owner;

    constructor(address _tokenContract, uint256 _txPerGigaTokenPerHour, uint256 _tokensToOwnUcac) public {
        owner = msg.sender;
        token = CPToken(_tokenContract);
        txPerGigaTokenPerHour = _txPerGigaTokenPerHour;
        transactionCost = 10 ** 27 / txPerGigaTokenPerHour;
        tokensToOwnUcac = _tokensToOwnUcac;
    }

    /**
     * Records a mutually confirmed credit transaction between two parties.
     *
     * @param _ucacContractAddr {address} - The address of the use case authority smart contract responsible for approving this transaction.
     * @param creditor {address} - The address of the party issuing the credit.
     * @param debtor {address} - The address of the party receiving the credit.
     * @param amount {uint256} - The amount of credit being issued.
     * @param creditorSignature {bytes32[3]} - The signature provided by the creditor (as [r, s, v]).
     * @param debtorSignature {bytes32[3]} - The signature provided by the debtor (as [r, s, v]).
     * @param memo {bytes32} - A brief, human-readable description of this transaction.
     */
    function issueCredit(address _ucacContractAddr, address creditor, address debtor, uint256 amount, bytes32[3] memory creditorSignature, bytes32[3] memory debtorSignature, bytes32 memo) public {
        require(amount > 0);
        require(creditor != debtor);
        require(tokensToOwnUcac <= ucacs[_ucacContractAddr].totalStakedTokens);
        uint256 nextTxLevel = currentTxLevel(_ucacContractAddr) + transactionCost;
        require(nextTxLevel <= ucacs[_ucacContractAddr].totalStakedTokens);
        require(balances[_ucacContractAddr][creditor] < balances[_ucacContractAddr][creditor] + int256(amount));
        require(balances[_ucacContractAddr][debtor] > balances[_ucacContractAddr][debtor] - int256(amount));

        uint256 nonce = getNonce(creditor, debtor);
        bytes32 hash = keccak256(prefix, keccak256(_ucacContractAddr, creditor, debtor, amount, nonce));

        require(ecrecover(hash, uint8(creditorSignature[2]), creditorSignature[0], creditorSignature[1]) == creditor);
        require(ecrecover(hash, uint8(debtorSignature[2]), debtorSignature[0], debtorSignature[1]) == debtor);

        require(BasicUCAC(_ucacContractAddr).allowTransaction(creditor, debtor, amount));

        balances[_ucacContractAddr][creditor] = balances[_ucacContractAddr][creditor] + int256(amount);
        balances[_ucacContractAddr][debtor] = balances[_ucacContractAddr][debtor] - int256(amount);

        ucacs[_ucacContractAddr].lastTxTimestamp = now;
        ucacs[_ucacContractAddr].txLevel = nextTxLevel;

        if (creditor < debtor) {
          nonces[creditor][debtor] = nonces[creditor][debtor] + 1;
        } else {
          nonces[debtor][creditor] = nonces[debtor][creditor] + 1;
        }

        emit IssueCredit(_ucacContractAddr, creditor, debtor, amount, nonce, memo);
    }

    /**
     * Registers a new use case authority contract (UCAC) with the Credit Protocol.
     *
     * @param _ucacContractAddr {address} - The address of the UCAC to register.
     * @param _denomination {bytes32} - A short, human-readable string representing the currency of transactions managed by this use case.
     * @param _tokensToStake {uint256} - The number of Credit Protocol tokens to stake in this use case.
     */
    function createAndStakeUcac(address _ucacContractAddr, bytes32 _denomination, uint256 _tokensToStake) public {
        require(_ucacContractAddr != address(0));
        require(ucacs[_ucacContractAddr].totalStakedTokens == 0);
        require(ucacs[_ucacContractAddr].ucacContractAddr == address(0));
        require(_tokensToStake >= tokensToOwnUcac);

        ucacs[_ucacContractAddr].ucacContractAddr = _ucacContractAddr;
        ucacs[_ucacContractAddr].denomination = _denomination;
        ucacs[_ucacContractAddr].totalStakedTokens = _tokensToStake;
        ucacs[_ucacContractAddr].txLevel = currentTxLevel(_ucacContractAddr);
        stakedTokensMap[_ucacContractAddr][msg.sender] = _tokensToStake;

        token.transferFrom(msg.sender, this, _tokensToStake);

        emit UcacCreation(_ucacContractAddr, _denomination);
    }

    /**
     * Stakes tokens in a registered use case authority contract (UCAC).
     * Staked tokens are transferred from the stakeholder to the Credit Protocol
     * to increase the transaction limit for this UCAC.
     *
     * @param _ucacContractAddr {address} - The address of the UCAC in which to stake tokens.
     * @param _numTokens {uint256} - The number of tokens to stake in this UCAC.
     */
    function stakeTokens(address _ucacContractAddr, uint256 _numTokens) public {
        require(_ucacContractAddr != address(0));
        require(_numTokens > 0);
        require(ucacs[_ucacContractAddr].ucacContractAddr != address(0));
        require(stakedTokensMap[_ucacContractAddr][msg.sender] < stakedTokensMap[_ucacContractAddr][msg.sender] + _numTokens);
        require(ucacs[_ucacContractAddr].totalStakedTokens < ucacs[_ucacContractAddr].totalStakedTokens + _numTokens);

        ucacs[_ucacContractAddr].totalStakedTokens = ucacs[_ucacContractAddr].totalStakedTokens + _numTokens;
        ucacs[_ucacContractAddr].txLevel = currentTxLevel(_ucacContractAddr);
        stakedTokensMap[_ucacContractAddr][msg.sender] = stakedTokensMap[_ucacContractAddr][msg.sender] + _numTokens;

        token.transferFrom(msg.sender, this, _numTokens);
    }

    /**
     * Unstakes tokens in a registered use case authority contract (UCAC).
     * Unstaked tokens are returned to the stakeholder by the Credit Protocol,
     * and will decrease the transaction limit for this UCAC.
     *
     * @param _ucacContractAddr {address} - The address of the UCAC in which to unstake tokens.
     * @param _numTokens {uint256} - The number of tokens to unstake in this UCAC.
     */
    function unstakeTokens(address _ucacContractAddr, uint256 _numTokens) public {
        require(_ucacContractAddr != address(0));
        require(_numTokens > 0);
        require(ucacs[_ucacContractAddr].ucacContractAddr != address(0));
        require(ucacs[_ucacContractAddr].totalStakedTokens - _numTokens < ucacs[_ucacContractAddr].totalStakedTokens);
        require(stakedTokensMap[_ucacContractAddr][msg.sender] - _numTokens < stakedTokensMap[_ucacContractAddr][msg.sender]);

        ucacs[_ucacContractAddr].totalStakedTokens = ucacs[_ucacContractAddr].totalStakedTokens - _numTokens;
        ucacs[_ucacContractAddr].txLevel = currentTxLevel(_ucacContractAddr);
        stakedTokensMap[_ucacContractAddr][msg.sender] = stakedTokensMap[_ucacContractAddr][msg.sender] - _numTokens;

        token.transfer(msg.sender, _numTokens);
    }

    /**
     * Only the contract owner may successfully call this function.
     * Sets the effectiveness of Credit Protocol tokens for affecting the
     * transaction limit for all use case authority contracts (UCACs).
     *
     * @param _txPerGigaTokenPerHour {uint256} - The new value to set.
     */
    function setTxPerGigaTokenPerHour(uint256 _txPerGigaTokenPerHour) public {
        require(msg.sender == owner);
        txPerGigaTokenPerHour = _txPerGigaTokenPerHour;
        transactionCost = 10 ** 27 / txPerGigaTokenPerHour;
    }

    /**
     * Only the contract owner may successfully call this function.
     * Sets the minimum number of tokens that must be staked in order to
     * register a new use case authority contract (UCAC). This also affects
     * the minimum number of tokens required to be staked in order for the
     * Credit Protocol to process transactions for a UCAC.
     *
     * @param _tokensToOwnUcac {uint256} - The new value to set.
     */
    function setTokensToOwnUcac(uint256 _tokensToOwnUcac) public {
        require(msg.sender == owner);
        tokensToOwnUcac = _tokensToOwnUcac;
    }

    /**
     * Only the contract owner may successfully call this function.
     * Transfers ownership of this contract to the given address.
     *
     * @param newOwner {address} - The address to which ownership will be transferred.
     */
    function transferOwnership(address newOwner) public {
      require(msg.sender == owner);
      require(newOwner != address(0));
      owner = newOwner;
      emit OwnershipTransferred(msg.sender, newOwner);
    }

    /**
     * Gets the current transaction level for a use case authority contract
     * (UCAC), expressed in tokens. If the transaction level for a UCAC meets
     * or exceeds the number of staked tokens, credit transactions cannot occur
     * until either some time has passed allowing for the transaction level to
     * decay, or additional tokens are staked.
     *
     * @param _ucacContractAddr {address} - The address of the UCAC whose level is to be inspected.
     *
     * @return {uint256} - The current transaction level, expressed in tokens.
     */
    function currentTxLevel(address _ucacContractAddr) public view returns (uint256) {
        uint256 currentDecay = ucacs[_ucacContractAddr].totalStakedTokens / 3600 * (now - ucacs[_ucacContractAddr].lastTxTimestamp);
        uint256 adjustedTxLevel = ucacs[_ucacContractAddr].txLevel < currentDecay ? 0 : ucacs[_ucacContractAddr].txLevel - currentDecay;
        return adjustedTxLevel;
    }

    /**
     * Gets the current nonce between the given pair of addresses.
     *
     * @param creditor {address} - One of the addresses in the pair.
     * @param debtor {address} - The other address in the pair.
     *
     * @return {uint256} - Returns the current nonce between the two given addresses.
     */
    function getNonce(address creditor, address debtor) public view returns (uint256) {
        require(creditor != address(0));
        require(debtor != address(0));
        require(creditor != debtor);

        if (creditor < debtor) {
          return nonces[creditor][debtor];
        }

        return nonces[debtor][creditor];
    }
}
