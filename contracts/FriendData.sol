pragma solidity 0.4.15;

import "blockmason-solidity-libs/contracts/Parentable.sol";

contract FriendData is Parentable {

    // ucac -> friend1 -> friend2 -> status
    mapping(bytes32 => mapping(address => mapping(address => bool))) public friendships;

    event IssueDebt(bytes32 ucac, address friend1, address friend2, uint256 amount);

    function issueDebt(bytes32 ucac, address friend1, address friend2) public {
        require(friendships[ucac][friend1][friend2]);
        IssueDebt(ucac, friend1, friend2, 10);
    }

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

    // either member of a friendship can destroy a friendship by signing a message
    // containing the hash of "destroy ucac friend"
    // function destroyFriendship() {}
}
