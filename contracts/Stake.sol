pragma solidity 0.4.15;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "tce-contracts/contracts/CPToken.sol";

contract Stake is Ownable {
    using SafeMath for uint256;

    struct Ucac {
        address ucacContractAddr;
        uint256 totalStakedTokens;
        address owner1;
        address owner2;
        uint256 txsLevel;
        uint256 lastTxTimestamp;
    }

    CPToken public token;
    uint public txPerTokenPerHour;
    uint public tokensToOwnUcac;

    mapping (bytes32 => Ucac) public ucacs; // indexed by ucacId
    /**
        @dev Indexed by token owner address => Ucac => amount of tokens
        // TODO perhaps switch the order of this ucac -> id -> int?
    **/
    mapping (address => mapping (bytes32 => uint)) public stakedTokensMap;

    function Stake(address _tokenContract, uint256 _txPerTokenPerHour, uint256 _tokensToOwnUcac) {
        token = CPToken(_tokenContract);
        txPerTokenPerHour = _txPerTokenPerHour;
        tokensToOwnUcac = _tokensToOwnUcac;
    }

    // TODO make onlyAdmin
    function setTxPerTokenPerHour(uint256 _txPerTokenPerHour) public {
        txPerTokenPerHour = _txPerTokenPerHour;
    }

    // TODO make onlyAdmin
    function setTokensToOwnUcac(uint256 _tokensToOwnUcac) public {
        tokensToOwnUcac = _tokensToOwnUcac;
    }

    // TODO this is incomplete. the logging should include information about the
    // debt and a debt object should be created for storage in a separate
    // contract.
    // TODO who should be able to call this?
    function ucacTx(bytes32 _ucacId) public {
        require(ucacInitialized(_ucacId));
        // get number of staked tokens
        uint256 totalStaked = ucacs[_ucacId].totalStakedTokens;

        uint256 currentDecay = totalStaked / 3600 * (now - ucacs[_ucacId].lastTxTimestamp);
        if (ucacs[_ucacId].txsLevel < currentDecay) {
            ucacs[_ucacId].txsLevel = 10 ** 18 / txPerTokenPerHour;
        } else {
            ucacs[_ucacId].txsLevel = ucacs[_ucacId].txsLevel - currentDecay + 10 ** 18 / txPerTokenPerHour;
        }

        require(totalStaked >= ucacs[_ucacId].txsLevel);
        ucacs[_ucacId].lastTxTimestamp = now;
    }

    /**
       @dev msg.sender must have approved StakeData to spend enough tokens
     **/
    function createAndStakeUcac(address _owner2, address _ucacContractAddr, bytes32 _ucacId, uint _tokensToStake) public {
        require(_tokensToStake >= tokensToOwnUcac);
        stakeTokens(_ucacId, msg.sender, _tokensToStake);
        ucacs[_ucacId].ucacContractAddr = _ucacContractAddr;
        ucacs[_ucacId].owner1 = msg.sender;
        ucacs[_ucacId].owner2 = _owner2;
    }

    function stakeTokens(bytes32 _ucacId, uint _tokensToStake) public {
        require(ucacInitialized(_ucacId));
        stakeTokens(_ucacId, msg.sender, _tokensToStake);
    }

    function ucacInitialized(bytes32 _ucacId) public constant returns (bool) {
        return ucacs[_ucacId].ucacContractAddr != address(0);
    }

    /* Token staking functionality */

    /**
        @dev only the parent contract can call this (to enable pausing of token staking for security reasons), but this locks in where tokens go to and how they are stored.
        // TODO who should be able to call this? I think everyone but we add a requirement that the token
        // allowance must be exactly _numTokens.
     **/
    function stakeTokens(bytes32 _ucacId, address _stakeholder, uint _numTokens) public {
        require(token.allowance(_stakeholder, this) >= _numTokens);
        uint256 updatedStakedTokens = stakedTokensMap[_stakeholder][_ucacId].add(_numTokens);
        stakedTokensMap[_stakeholder][_ucacId] = updatedStakedTokens;
        uint256 updatedNumTokens =  ucacs[_ucacId].totalStakedTokens.add(_numTokens);
        ucacs[_ucacId].totalStakedTokens = updatedNumTokens;
        token.transferFrom(_stakeholder, this, _numTokens);
    }

    /**
       @notice Checks if this address is already in this name.
       @param _ucacId Id of the ucac tokens are staked to
       @param _numTokens Number of tokens the user wants to unstake
     **/
    function unstakeTokens(bytes32 _ucacId, uint _numTokens) public {
        // SafeMath will throw if _numTokens is greater than a sender's stakedTokens amount
        uint256 updatedStakedTokens = stakedTokensMap[msg.sender][_ucacId].sub(_numTokens);
        stakedTokensMap[msg.sender][_ucacId] = updatedStakedTokens;
        uint256 updatedNumTokens = ucacs[_ucacId].totalStakedTokens.sub(_numTokens);
        ucacs[_ucacId].totalStakedTokens = updatedNumTokens;
        token.transfer(msg.sender, _numTokens);
    }
}
