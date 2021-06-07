pragma solidity >0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./oz/Ownable.sol";

contract GuildBank is Ownable {
    using SafeMath for uint256;

    IERC20 public approvedToken; // approved token contract reference

    event Withdrawal(address indexed receiver, uint256 amount);

    constructor(address approvedTokenAddress) public {
        approvedToken = IERC20(approvedTokenAddress);
    }

    function withdraw(
        address receiver,
        uint256 shares,
        uint256 totalShares
    ) public onlyOwner returns (bool) {
        uint256 amount =
            approvedToken.balanceOf(address(this)).mul(shares).div(totalShares);
        emit Withdrawal(receiver, amount);
        return approvedToken.transfer(receiver, amount);
    }

    function transfer(address receiver, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        emit Withdrawal(receiver, amount);
        return approvedToken.transfer(receiver, amount);
    }
}
