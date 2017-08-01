pragma solidity ^0.4.11;

/*  Fluxxy
    The Flux Capacitor

 */

contract Fluxxy {
  /*
    mirrors the FIDData functions (getters and setters)
    but also receives a token parameter
    1. checks Staker to get
    - user associated with token + contract
    - total capacity remaining in the time period for the user/token
    2. if there is capacity remaining
    - updates capacity in Staker
    - calls the corresponding function in FIDData
    3. if no capacity remaining, revert()

   */
}
