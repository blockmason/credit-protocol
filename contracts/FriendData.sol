pragma solidity ^0.4.15;

import "blockmason-solidity-libs/contracts/Parentable.sol";

contract FriendData is Parentable {

  struct Friend {
    bytes32 friend1;
    bytes32 friend2;
    uint256 id;
  }

  event Debug1(address expectedSigner, address signer);
  event Debug(bytes32 hash);

  function initFriendship( bytes32 ucac, address friend1, address friend2
                         , bytes32 sig1r, bytes32 sig1s, uint8 sig1v
                         , bytes32 sig2r, bytes32 sig2s, uint8 sig2v
                         ) public constant returns (bool) {
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    bool validSig1 = ecrecover(keccak256(prefix, keccak256(ucac, friend2)), sig1v, sig1r, sig1s) == friend1;
    bool validSig2 = ecrecover(keccak256(prefix, keccak256(ucac, friend1)), sig2v, sig2r, sig2s) == friend2;
    return validSig1 && validSig2;
  }
}
