// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SeedlexLogger
 * @dev Simple contract to log Seedlex wallet activities on Celo mainnet
 */
contract SeedlexLogger {
    
    struct Transaction {
        address user;
        string action;
        uint256 amount;
        uint256 timestamp;
    }
    
    Transaction[] public transactions;
    mapping(address => uint256) public userTransactionCount;
    
    event ActivityLogged(address indexed user, string action, uint256 amount, uint256 timestamp);
    event WalletCreated(address indexed user, uint256 timestamp);
    
    // Log wallet creation
    function logWalletCreation() external {
        emit WalletCreated(msg.sender, block.timestamp);
        userTransactionCount[msg.sender]++;
    }
    
    // Log generic activity
    function logActivity(string memory _action, uint256 _amount) external {
        transactions.push(Transaction({
            user: msg.sender,
            action: _action,
            amount: _amount,
            timestamp: block.timestamp
        }));
        
        userTransactionCount[msg.sender]++;
        emit ActivityLogged(msg.sender, _action, _amount, block.timestamp);
    }
    
    // Get total transactions
    function getTotalTransactions() external view returns (uint256) {
        return transactions.length;
    }
    
    // Get user transaction count
    function getUserTransactions(address _user) external view returns (uint256) {
        return userTransactionCount[_user];
    }
    
    // Get transaction by index
    function getTransaction(uint256 _index) external view returns (
        address user,
        string memory action,
        uint256 amount,
        uint256 timestamp
    ) {
        require(_index < transactions.length, "Invalid index");
        Transaction memory txn = transactions[_index];
        return (txn.user, txn.action, txn.amount, txn.timestamp);
    }
}
