pragma solidity ^0.4.6;

import "StandardToken.sol";

/// @title Token contract - Implements Standard Token Interface with HumaniQ features.
/// @author Evgeny Yurtaev - <evgeny@etherionlab.com>
contract TokenFund is StandardToken {

    /*
     * Token meta data
     */
    string constant public name = "TheToken Fund";
    string constant public symbol = "TKN";
    uint8 constant public decimals = 8;

    /*
     * Storage
     */
    address public multisig;
    address public owner = 0x0;
    uint public tokenPrice = 1 finney; // 0.001 ETH
    // bool emissionEnabled = true;
    // bool transfersEnabled = true;

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
        uint balance = balances[msg.sender];
        if (balance < tokenCount) {
            return false;
        }
        balances[msg.sender] -= tokenCount;
        totalSupply -= tokenCount;
        return true;
    }

    /// @dev TokenFund emission function.
    /// @param _for Address of receiver.
    /// @param tokenCount Number of tokens to issue.
    function issueTokens(address _for, uint tokenCount)
        private
        returns (bool)
    {
        if (tokenCount == 0) {
            return false;
        }
        balances[_for] += tokenCount;
        totalSupply += tokenCount;
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

    /// @dev Sets token price (TKN/ETH) in Wei.
    /// @param valueInWei New value.
    function setTokenPrice(uint valueInWei)
        public
        onlyOwner
        returns (bool)
    {
        tokenPrice = valueInWei;
        return true;
    }

    /// @dev Contract constructor function sets initial token balances.
    /// @param _multisig Address of the owner of TokenFund.
    function TokenFund(address _multisig)
    {
        totalSupply = 0;
        owner = msg.sender;
        multisig = _multisig;
    }

    /// @dev Fallback function. Calls fund() function to create tokens.
    function () payable {
        fund();
    }
}