pragma solidity 0.4.15;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./BasicUCAC.sol";
import "./Stake.sol";

contract CreditProtocol is Ownable {

    // id -> id -> # of transactions in all UCACs
    // lesser id is must always be the first argument
    mapping(address => mapping(address => uint256)) public nonces;
    // ucac -> id -> balance
    mapping(bytes32 => mapping(address => int256)) public balances;

    // the standard prefix appended to 32-byte-long messages when signed by an
    // Ethereum client
    bytes prefix = "\x19Ethereum Signed Message:\n32";

    event IssueCredit(bytes32 indexed ucac, address indexed creditor, address indexed debtor, uint256 amount);

    Stake public stakeContract;

    function CreditProtocol(Stake _stakeContract) {
        stakeContract = _stakeContract;
    }

    function getNonce(address p1, address p2) public constant returns (uint256) {
        return p1 < p2 ? nonces[p1][p2] : nonces[p2][p1];
    }

    function issueCredit( bytes32 ucac, address creditor, address debtor, uint256 amount
                      , bytes32 sig1r, bytes32 sig1s, uint8 sig1v
                      , bytes32 sig2r, bytes32 sig2s, uint8 sig2v
                      ) public {
        require(creditor != debtor);

        bytes32 hash = keccak256(prefix, keccak256(ucac, creditor, debtor, amount, getNonce(creditor, debtor)));

        // verifying signatures
        require(ecrecover(hash, sig1v, sig1r, sig1s) == creditor);
        require(ecrecover(hash, sig2v, sig2r, sig2s) == debtor);

        // checking for overflow
        require(balances[ucac][creditor] < balances[ucac][creditor] + int256(amount));
        // checking for underflow
        require(balances[ucac][debtor] > balances[ucac][debtor] - int256(amount));
        // executeUcacTx will throw if a transaction limit has been reached or the ucac is uninitialized
        stakeContract.executeUcacTx(ucac);
        // check that UCAC contract approves the transaction
        require(BasicUCAC(stakeContract.getUcacAddr(ucac)).allowTransaction(creditor, debtor, amount));

        balances[ucac][creditor] = balances[ucac][creditor] + int256(amount);
        balances[ucac][debtor] = balances[ucac][debtor] - int256(amount);
        IssueCredit(ucac, creditor, debtor, amount);
        incrementNonce(creditor, debtor);
    }

    function incrementNonce(address p1, address p2) private {
        if (p1 < p2) {
            nonces[p1][p2] = nonces[p1][p2] + 1;
        } else {
            nonces[p2][p1] = nonces[p2][p1] + 1;
        }
    }
}
