pragma solidity >0.6.0;

import "./oz/ERC20.sol";

contract Token is ERC20 {
    constructor(uint256 supply) public ERC20("Moloch USD", "MUSD", 18) {
        _mint(msg.sender, supply);
    }
}
