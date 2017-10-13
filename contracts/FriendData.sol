pragma solidity 0.4.15;

import "blockmason-solidity-libs/contracts/Parentable.sol";

contract FriendData is Parentable {

    mapping(address => mapping(address => uint256)) public nonces;
    mapping(bytes32 => mapping(address => int256)) public balances;

    bytes prefix = "\x19Ethereum Signed Message:\n32";
    event IssueDebt(bytes32 indexed ucac, address indexed creditor, address indexed debtor, uint256 amount);

    function getNonce(address p1, address p2) public constant returns (uint256) {
        uint256 nonce = p1 < p2 ? nonces[p1][p2] : nonces[p2][p1];
        return nonce;
    }

    function issueDebt( bytes32 ucac, address creditor, address debtor, uint256 amount
                      , bytes32 sig1r, bytes32 sig1s, uint8 sig1v
                      , bytes32 sig2r, bytes32 sig2s, uint8 sig2v
                      ) public {
        require(creditor != debtor);
        uint256 nonce = getNonce(creditor, debtor);
        bool validSigC = ecrecover(keccak256(prefix, keccak256(ucac, creditor, debtor, amount, nonce)), sig1v, sig1r, sig1s) == creditor;
        bool validSigD = ecrecover(keccak256(prefix, keccak256(ucac, creditor, debtor, amount, nonce)), sig2v, sig2r, sig2s) == debtor;
        require(validSigC && validSigD);
        IssueDebt(ucac, creditor, debtor, amount);
        // TODO check over- / underflow
        balances[ucac][creditor] = balances[ucac][creditor] + int256(amount);
        balances[ucac][debtor] = balances[ucac][debtor] - int256(amount);
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
