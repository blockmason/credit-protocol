pragma solidity 0.4.15;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "tce-contracts/contracts/CPToken.sol";
import "./BasicUCAC.sol";

contract CreditProtocol is Ownable {
    using SafeMath for uint256;

    struct Ucac {
        address ucacContractAddr;
        uint256 totalStakedTokens;
        uint256 txLevel;
        uint256 lastTxTimestamp;
        bytes32 denomination;
    }

    CPToken public token;
    uint256 public txPerGigaTokenPerHour; // gigatoken = 10 ^ 9 nominal tokens
    uint256 public tokensToOwnUcac;

    mapping (address => Ucac) public ucacs; // ucacAddress -> Ucac struct

    // ucacAddr -> token owner address -> amount of tokens
    mapping (address => mapping (address => uint256)) public stakedTokensMap;

    // id -> id -> # of transactions in all UCACs
    // lesser id is must always be the first argument
    mapping(address => mapping(address => uint256)) public nonces;
    // ucacAddr -> id -> balance
    mapping(address => mapping(address => int256)) public balances;

    // the standard prefix appended to 32-byte-long messages when signed by an
    // Ethereum client
    bytes prefix = "\x19Ethereum Signed Message:\n32";

    event IssueCredit(address indexed ucac, address indexed creditor, address indexed debtor, uint256 amount, uint256 nonce, bytes32 memo);
    event UcacCreation(address indexed ucac, bytes32 denomination);

    function CreditProtocol(address _tokenContract, uint256 _txPerGigaTokenPerHour, uint256 _tokensToOwnUcac) {
        token = CPToken(_tokenContract);
        txPerGigaTokenPerHour = _txPerGigaTokenPerHour;
        tokensToOwnUcac = _tokensToOwnUcac;
    }

    function getNonce(address p1, address p2) public constant returns (uint256) {
        return p1 < p2 ? nonces[p1][p2] : nonces[p2][p1];
    }

    function issueCredit( address _ucacContractAddr, address creditor, address debtor, uint256 amount
                        , bytes32[3] memory sig1
                        , bytes32[3] memory sig2
                        , bytes32 memo
                        ) public {
        require(creditor != debtor);
        uint256 nonce = getNonce(creditor, debtor);
        bytes32 hash = keccak256(prefix, keccak256(_ucacContractAddr, creditor, debtor, amount, nonce));

        // verifying signatures
        require(ecrecover(hash, uint8(sig1[2]), sig1[0], sig1[1]) == creditor);
        require(ecrecover(hash, uint8(sig2[2]), sig2[0], sig2[1]) == debtor);

        // checking for overflow
        require(balances[_ucacContractAddr][creditor] < balances[_ucacContractAddr][creditor] + int256(amount));
        // checking for underflow
        require(balances[_ucacContractAddr][debtor] > balances[_ucacContractAddr][debtor] - int256(amount));
        // executeUcacTx will throw if a transaction limit has been reached or the ucac is uninitialized
        executeUcacTx(_ucacContractAddr);
        // check that UCAC contract approves the transaction
        require(BasicUCAC(_ucacContractAddr).allowTransaction(creditor, debtor, amount));

        balances[_ucacContractAddr][creditor] = balances[_ucacContractAddr][creditor] + int256(amount);
        balances[_ucacContractAddr][debtor] = balances[_ucacContractAddr][debtor] - int256(amount);
        IssueCredit(_ucacContractAddr, creditor, debtor, amount, nonce, memo);
        incrementNonce(creditor, debtor);
    }

    function incrementNonce(address p1, address p2) private {
        if (p1 < p2) {
            nonces[p1][p2] = nonces[p1][p2] + 1;
        } else {
            nonces[p2][p1] = nonces[p2][p1] + 1;
        }
    }

    // Staking

    /**
       @dev The gigatokens of `_txPerGigaTokenPerHour` are nominal giga tokens, that is
       10 ^ 18 * 10 ^ 9 = 10 ^ 27 attotokens
     **/
    function setTxPerGigaTokenPerHour(uint256 _txPerGigaTokenPerHour) public onlyOwner {
        txPerGigaTokenPerHour = _txPerGigaTokenPerHour;
    }

    function setTokensToOwnUcac(uint256 _tokensToOwnUcac) public onlyOwner {
        tokensToOwnUcac = _tokensToOwnUcac;
    }

    function currentTxLevel(address _ucacContractAddr) public constant returns (uint256) {
        uint256 totalStaked = ucacs[_ucacContractAddr].totalStakedTokens;
        uint256 currentDecay = totalStaked / 3600 * (now - ucacs[_ucacContractAddr].lastTxTimestamp);
        uint256 adjustedTxLevel = ucacs[_ucacContractAddr].txLevel < currentDecay ? 0 : ucacs[_ucacContractAddr].txLevel - currentDecay;
        return adjustedTxLevel;
    }

    function executeUcacTx(address _ucacContractAddr) public {
        uint256 txLevelBeforeCurrentTx = currentTxLevel(_ucacContractAddr);
        uint256 txLevelAfterCurrentTx = txLevelBeforeCurrentTx + 10 ** 27 / txPerGigaTokenPerHour;
        require(ucacs[_ucacContractAddr].totalStakedTokens >= txLevelAfterCurrentTx);
        require(ucacs[_ucacContractAddr].totalStakedTokens >= tokensToOwnUcac);
        ucacs[_ucacContractAddr].lastTxTimestamp = now;
        ucacs[_ucacContractAddr].txLevel = txLevelAfterCurrentTx;
    }

    /**
       @dev msg.sender must have approved Stake contract to transfer at least `_tokensToStake` tokens.
            `_tokensToStake` is measured in attotokens.
     **/
    function createAndStakeUcac( address _ucacContractAddr, bytes32 _denomination
                               , uint256 _tokensToStake) public {
        // check that _ucacContractAddr points to something meaningful
        require(_ucacContractAddr != address(0));
        // check that _ucacContractAddr does not point to an extant UCAC
        require(ucacs[_ucacContractAddr].totalStakedTokens == 0 && ucacs[_ucacContractAddr].ucacContractAddr == address(0));
        // checking that initial token staking amount is enough to own a UCAC
        require(_tokensToStake >= tokensToOwnUcac);
        stakeTokensInternal(_ucacContractAddr, msg.sender, _tokensToStake);
        ucacs[_ucacContractAddr].ucacContractAddr = _ucacContractAddr;
        ucacs[_ucacContractAddr].denomination = _denomination;
        UcacCreation(_ucacContractAddr, _denomination);
    }

    /* Token staking functionality */

    /**
       @dev msg.sender must have approved Stake contract to transfer at least `_numTokens` tokens
       `_numTokens` is measured in attotokens.
     **/
    function stakeTokens(address _ucacContractAddr, uint256 _numTokens) public {
        // check that _ucacContractAddr points to an extant UCAC
        require(ucacs[_ucacContractAddr].ucacContractAddr != address(0));
        stakeTokensInternal(_ucacContractAddr, msg.sender, _numTokens);
    }

    /**
       @notice Checks if this address is already in this name.
       @param _ucacContractAddr Id of the ucac tokens are staked to
       @param _numTokens Number of attotokens the user wants to unstake
     **/
    function unstakeTokens(address _ucacContractAddr, uint256 _numTokens) public {
        // SafeMath will throw if _numTokens is greater than a sender's stakedTokens amount
        uint256 updatedStakedTokens = stakedTokensMap[_ucacContractAddr][msg.sender].sub(_numTokens);
        stakedTokensMap[_ucacContractAddr][msg.sender] = updatedStakedTokens;
        uint256 updatedNumTokens = ucacs[_ucacContractAddr].totalStakedTokens.sub(_numTokens);

        // updating txLevel to ensure accurate decay calculation
        ucacs[_ucacContractAddr].txLevel = currentTxLevel(_ucacContractAddr);

        ucacs[_ucacContractAddr].totalStakedTokens = updatedNumTokens;
        token.transfer(msg.sender, _numTokens);
    }

    // Private Functions

    function stakeTokensInternal(address _ucacContractAddr, address _stakeholder, uint256 _numTokens) private {
        token.transferFrom(_stakeholder, this, _numTokens);
        uint256 updatedStakedTokens = stakedTokensMap[_ucacContractAddr][_stakeholder].add(_numTokens);
        stakedTokensMap[_ucacContractAddr][_stakeholder] = updatedStakedTokens;

        // updating txLevel to ensure accurate decay calculation
        ucacs[_ucacContractAddr].txLevel = currentTxLevel(_ucacContractAddr);

        uint256 updatedNumTokens =  ucacs[_ucacContractAddr].totalStakedTokens.add(_numTokens);
        ucacs[_ucacContractAddr].totalStakedTokens = updatedNumTokens;
    }

}
