// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title NovaClassTicket
 * @dev Time-bound access pass system with expiry mechanism
 * @notice Users can purchase access passes that expire after a set duration
 */
contract NovaClassTicket {
    
    // ============ State Variables ============
    
    /// @notice Price to purchase an access pass (in wei)
    uint256 public passPrice;
    
    /// @notice Duration of access in seconds (e.g., 30 days = 30 * 24 * 60 * 60)
    uint256 public passDuration;
    
    /// @notice Contract owner address
    address public owner;
    
    /// @notice Mapping from user address to pass expiry timestamp
    mapping(address => uint256) public passExpiry;
    
    // ============ Events ============
    
    /// @notice Emitted when a user purchases an access pass
    /// @param buyer Address of the pass purchaser
    /// @param expiryTime Timestamp when the pass expires
    /// @param pricePaid Amount paid for the pass
    event AccessPurchased(
        address indexed buyer,
        uint256 expiryTime,
        uint256 pricePaid
    );
    
    /// @notice Emitted when owner withdraws funds
    /// @param owner Address of the owner
    /// @param amount Amount withdrawn
    event FundsWithdrawn(address indexed owner, uint256 amount);
    
    /// @notice Emitted when pass price is updated
    /// @param newPrice New price in wei
    event PriceUpdated(uint256 newPrice);
    
    /// @notice Emitted when pass duration is updated
    /// @param newDuration New duration in seconds
    event DurationUpdated(uint256 newDuration);
    
    // ============ Errors ============
    
    error InsufficientPayment();
    error NoAccess();
    error OnlyOwner();
    error WithdrawalFailed();
    
    // ============ Modifiers ============
    
    /// @notice Restricts function access to contract owner only
    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }
    
    // ============ Constructor ============
    
    /// @notice Initializes the contract with price and duration
    /// @param _passPrice Price of access pass in wei
    /// @param _passDurationDays Duration of pass validity in days
    constructor(uint256 _passPrice, uint256 _passDurationDays) {
        owner = msg.sender;
        passPrice = _passPrice;
        passDuration = _passDurationDays * 1 days; // Convert days to seconds
    }
    
    // ============ Main Functions ============
    
    /// @notice Purchase an access pass
    /// @dev Extends existing pass if user already has one
    function buyPass() external payable {
        if (msg.value < passPrice) revert InsufficientPayment();
        
        uint256 newExpiry;
        
        // If user has an active pass, extend from current expiry
        // Otherwise, extend from current time
        if (passExpiry[msg.sender] > block.timestamp) {
            newExpiry = passExpiry[msg.sender] + passDuration;
        } else {
            newExpiry = block.timestamp + passDuration;
        }
        
        passExpiry[msg.sender] = newExpiry;
        
        emit AccessPurchased(msg.sender, newExpiry, msg.value);
        
        // Refund excess payment
        if (msg.value > passPrice) {
            (bool success, ) = msg.sender.call{value: msg.value - passPrice}("");
            require(success, "Refund failed");
        }
    }
    
    /// @notice Check if an address has valid access
    /// @param user Address to check
    /// @return bool True if user has active access, false otherwise
    function hasAccess(address user) public view returns (bool) {
        return passExpiry[user] > block.timestamp;
    }
    
    /// @notice Get remaining time on a user's pass
    /// @param user Address to check
    /// @return uint256 Seconds remaining (0 if expired)
    function getTimeRemaining(address user) public view returns (uint256) {
        if (passExpiry[user] <= block.timestamp) {
            return 0;
        }
        return passExpiry[user] - block.timestamp;
    }
    
    /// @notice Check current user's access status
    /// @return bool True if caller has active access
    function myAccess() external view returns (bool) {
        return hasAccess(msg.sender);
    }
    
    // ============ Owner Functions ============
    
    /// @notice Update the price of access passes
    /// @param _newPrice New price in wei
    function updatePrice(uint256 _newPrice) external onlyOwner {
        passPrice = _newPrice;
        emit PriceUpdated(_newPrice);
    }
    
    /// @notice Update the duration of access passes
    /// @param _newDurationDays New duration in days
    function updateDuration(uint256 _newDurationDays) external onlyOwner {
        passDuration = _newDurationDays * 1 days;
        emit DurationUpdated(passDuration);
    }
    
    /// @notice Withdraw contract balance to owner
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner.call{value: balance}("");
        if (!success) revert WithdrawalFailed();
        emit FundsWithdrawn(owner, balance);
    }
    
    /// @notice Get contract balance
    /// @return uint256 Current balance in wei
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    // ============ Helper Functions ============
    
    /// @notice Convert wei to ether for easy reading
    /// @param weiAmount Amount in wei
    /// @return uint256 Amount in ether (with 18 decimals)
    function weiToEther(uint256 weiAmount) public pure returns (uint256) {
        return weiAmount / 1 ether;
    }
}