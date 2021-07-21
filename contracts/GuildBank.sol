pragma solidity 0.5.3;

import "./oz/Ownable.sol";

contract GuildBank is Ownable {
	using SafeMath for uint256;

	IERC20 private contributionToken; // contribution token contract reference

	event Withdrawal(address indexed receiver, uint256 amount);
	event FundsWithdrawal(address indexed applicant, uint256 fundsRequested);
	event AssetWithdrawal(IERC20 assetToken, address indexed receiver, uint256 amount);
	
	// contributionToken is used to fund ventures and distribute dividends, e.g., wETH or DAI
	constructor(address contributionTokenAddress) public {
    		contributionToken = IERC20(contributionTokenAddress);
	}

    	// pairs to VentureMoloch member ragequit mechanism
	function withdraw(address receiver, uint256 amount) public onlyOwner returns (bool) {
    		emit Withdrawal(receiver, amount);
    		return contributionToken.transfer(receiver, amount);
	}
	
	// pairs to VentureMoloch member dividend claiming mechanism
	function withdrawDividend(address receiver, uint256 amount) public onlyOwner returns (bool) {
    		emit Withdrawal(receiver, amount);
    		return contributionToken.transfer(receiver, amount);
	}
    
        // pairs to VentureMoloch funding proposal mechanism. 
        // Funds are withdrawn on processProposal
	function withdrawFunds(address applicant, uint256 fundsRequested) public onlyOwner returns (bool) {
    		emit FundsWithdrawal(applicant, fundsRequested);
    		return contributionToken.transfer(applicant, fundsRequested);
	}
	
	// onlySummoner in Moloch can withdraw and administer investment tokens
	function adminWithdrawAsset(IERC20 assetToken, address receiver, uint256 amount) public onlyOwner returns(bool) {
		emit AssetWithdrawal(assetToken, receiver, amount);
		return IERC20(assetToken).transfer(receiver, amount);
	}
}
