pragma solidity 0.4.15;

import "blockmason-solidity-libs/contracts/Parentable.sol";

contract FriendData is Parentable {

    // ucac -> friend1 -> friend2 -> status -- TOOD delete this, just for show, not necessary
    // might use this as a nons
    mapping(bytes32 => mapping(address => mapping(address => bool))) public friendships;

    mapping(bytes32 => mapping(address => int256)) public balances;

    event IssueDebt(bytes32 indexed ucac, address indexed creditor, address indexed debtor, uint256 amount);

    // TODO (incomplete: think of a strategy for generating a nonce; param hashes much always be unique)
    // obvious thing to do would be to keep a record of # of transactions between 2 friends...
    // would we be willing to pay for that storage?
    function issueDebt( bytes32 ucac, address creditor, address debtor, uint256 amount
                      , bytes32 sig1r, bytes32 sig1s, uint8 sig1v
                      , bytes32 sig2r, bytes32 sig2s, uint8 sig2v
                      ) public {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bool validSigC = ecrecover(keccak256(prefix, keccak256(ucac, debtor, amount)), sig1v, sig1r, sig1s) == creditor;
        bool validSigD = ecrecover(keccak256(prefix, keccak256(ucac, creditor, amount)), sig2v, sig2r, sig2s) == debtor;
        require(validSigC && validSigD);
        IssueDebt(ucac, creditor, debtor, amount);
        // TODO check over- / underflow
        balances[ucac][creditor] = balances[ucac][creditor] + int256(amount);
        balances[ucac][debtor] = balances[ucac][debtor] - int256(amount);
    }

    // TODO delete this, just for show not necessary
    function initFriendship( bytes32 ucac, address friend1, address friend2
                           , bytes32 sig1r, bytes32 sig1s, uint8 sig1v
                           , bytes32 sig2r, bytes32 sig2s, uint8 sig2v
                           ) public {
        require(friend1 < friend2);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bool validSig1 = ecrecover(keccak256(prefix, keccak256(ucac, friend2)), sig1v, sig1r, sig1s) == friend1;
        bool validSig2 = ecrecover(keccak256(prefix, keccak256(ucac, friend1)), sig2v, sig2r, sig2s) == friend2;
        require(validSig1 && validSig2);
        friendships[ucac][friend1][friend2] = true;
    }
}
