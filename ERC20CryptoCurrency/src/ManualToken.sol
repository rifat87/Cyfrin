// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ManualToken {
    error InsufficientBalance(uint256 available, uint256 required);


    mapping (address => uint256) private s_balances;
    function name() public pure returns (string memory) {
        return "Hadia";
    }

    function totalSupply() public pure returns (uint256) {
        return 100 ether; // 1000000000000000000
    }

    function decimals() public pure  returns (uint256) {
        return 18;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return s_balances[_owner];
    }

    //Transfer function
    function transfer(address _to, uint256 _amount) public {
        if (s_balances[msg.sender] < _amount) {
            revert InsufficientBalance({
                available: s_balances[msg.sender],
                required: _amount
            });
        }

        uint256 previousBalances = s_balances[msg.sender] + s_balances[_to];

        // Perform the transfer
        s_balances[msg.sender] -= _amount;
        s_balances[_to] += _amount;

        // Ensure the invariant holds
        require(s_balances[msg.sender] + s_balances[_to] == previousBalances, "Transfer invariant violated");
    }
}