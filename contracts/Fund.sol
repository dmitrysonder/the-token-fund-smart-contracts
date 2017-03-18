pragma solidity ^0.4.6;

import "./TokenFund.sol";

contract Fund {

	/*
     * External contracts
     */
    TokenFund public tokenFund;

	/*
     * Storage
     */
    address public multisig;
    address public owner = 0x0;
    address public supportAddress;
    uint public tokenPrice = 1 finney; // 0.001 ETH

    mapping (address => address) public referrals;

    /*
     * Modifiers
     */

    modifier onlyOwner() {
        // Only owner is allowed to do this action.
        if (msg.sender != owner) {
            throw;
        }
        _;
    }

    /*
     * Contract functions
     */

	/// @dev Withdraws tokens for msg.sender.
    /// @param tokenCount Number of tokens to withdraw.
    function withdrawTokens(uint tokenCount)
        public
        returns (bool)
    {
        return tokenFund.withdrawTokens(tokenCount);
    }

    function issueTokens(address _for, uint tokenCount) 
    	private
    	returns (bool) 
    {
    	if (tokenCount == 0) {
            return false;
        }

        var percent = tokenCount / 100;

        // 1% goes to the fund managers
        if (!tokenFund.issueTokens(multisig, percent)) {
            // Tokens could not be issued.
            throw;
        }

		// 1% goes to the support team
        if (!tokenFund.issueTokens(supportAddress, percent)) {
            // Tokens could not be issued.
            throw;
        }

        if (referrals[_for] != 0) {
        	// 3% goes to the referral
        	if (!tokenFund.issueTokens(referrals[_for], 3 * percent)) {
	            // Tokens could not be issued.
	            throw;
	        }
        } else {
        	// if there is no referral, 3% goes to the fund managers
        	if (!tokenFund.issueTokens(multisig, 3 * percent)) {
	            // Tokens could not be issued.
	            throw;
	        }
        }

        if (!tokenFund.issueTokens(_for, tokenCount - 5 * percent)) {
            // Tokens could not be issued.
            throw;
	    }

	    return true;
    }

    /// @dev Issues tokens for users who made BTC purchases.
    /// @param beneficiary Address the tokens will be issued to.
    /// @param tokenCount Number of tokens to issue
    function fundBTC(address beneficiary, uint tokenCount)
        external
        onlyOwner
        returns (bool)
    {	
    	return issueTokens(beneficiary, tokenCount);
    }

    /// @dev Issues tokens for users who made direct ETH payment.
    function fund()
        public
        payable
        returns (bool)
    {
        // Token count is rounded down. Sent ETH should be multiples of baseTokenPrice.
        address beneficiary = msg.sender;
        uint tokenCount = msg.value / tokenPrice;
        uint roundedInvestment = msg.value * tokenPrice;

        // Send change back to user.
        if (msg.value > roundedInvestment && !beneficiary.send(msg.value - roundedInvestment)) {
            throw;
        }
        return issueTokens(beneficiary, tokenCount);
    }

    function setReferral(address client, address referral)
        public
        onlyOwner
    {
        referrals[client] = referral;
    }

    function getReferral(address client) 
        public
        constant
        returns (address)
    {
        return referrals[client];
    }

    /// @dev Sets token price (TKN/ETH) in Wei.
    /// @param valueInWei New value.
    function setTokenPrice(uint valueInWei)
        public
        onlyOwner
    {
        tokenPrice = valueInWei;
    }

    /// @dev Contract constructor function
    /// @param _multisig Address of the owner of TokenFund.
    /// @param _supportAddress Address of the developers team.
    /// @param _tokenAddress Address of the token contract.
    function Fund(address _owner, address _multisig, address _supportAddress, address _tokenAddress)
    {
        owner = _owner;
        multisig = _multisig;
        supportAddress = _supportAddress;
        tokenFund = TokenFund(_tokenAddress);
    }

    /// @dev Fallback function. Calls fund() function to create tokens.
    function () payable {
        fund();
    }
}