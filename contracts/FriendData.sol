pragma solidity ^0.4.15;

import "blockmason-solidity-libs/contracts/Parentable.sol";

contract FriendData is Parentable {

  struct Friend {
    bytes32 friend1;
    bytes32 friend2;
    uint256 id;
  }

  function initFriendship( bytes32 ucac, address friend1, address friend2, bytes32 data
                         , bytes32 sig1r, bytes32 sig1s, uint8 sig1v
                         , bytes32 sig2r, bytes32 sig2s, uint8 sig2v
                         ) public constant returns (bool) {
    bytes32 expectedData = keccak256(ucac);
    // require(expectedData == data);
    bool validSig1 = ecrecover(data, sig1v, sig1r, sig1s) == friend1;
    return validSig1;
    // bytes32 expectedSignedHash = keccak256(ucac, friend2, sig1r, sig1s, sig1v);
    // require(ecrecover(expectedSignedHash, sigdata[i][0], sigdata[i][1], sigdata[i][2]) == friend2);
  }
}
