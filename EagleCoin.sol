/**
 *Submitted for verification at BscScan.com on 2024-11-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract EagleCoin is IBEP20, Ownable {
    string public constant name = "Eagle Coin";  // Token Name
    string public constant symbol = "EGC";       // Token Symbol
    uint8 public constant decimals = 18;         // Decimals for token

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _blacklist;  // Blacklist to prevent certain addresses from transferring/swapping
    mapping(address => bool) private _isDEXRouter;  // Mapping to identify known DEX routers (e.g., PancakeSwap Router)
    
    bool private _paused;  // Pause the contract in case of emergency

    // Constructor to initialize the total supply and set up the DEX router addresses
    constructor() {
        _totalSupply = 2100000 * 10**uint256(decimals); // 2.1 million tokens with 18 decimals
        _balances[msg.sender] = _totalSupply; // Assign all initial tokens to the contract deployer's address
        emit Transfer(address(0), msg.sender, _totalSupply); // Emit a transfer event from zero address to the deployer's address

        // Add known DEX router addresses to the _isDEXRouter mapping (example: PancakeSwap Router)
        
        _isDEXRouter[0x10ED43C718714eb63d5aA57B78B54704E256024E] = true; // PancakeSwap Router (example address, please verify the actual address)
        _paused = false;  // Initially, the contract is not paused
    }

    modifier onlyWhenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    modifier notBlacklisted(address account) {
        require(!_blacklist[account], "BEP20: Address is blacklisted");
        _;
    }

    modifier noSwapToDEX(address recipient) {
        require(!_isDEXRouter[recipient], "BEP20: Swapping to a DEX is not allowed");
        _;
    }

    // --- BEP20 Implementation ---
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override notBlacklisted(msg.sender) notBlacklisted(recipient) noSwapToDEX(recipient) onlyWhenNotPaused returns (bool) {
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(_balances[msg.sender] >= amount, "BEP20: transfer amount exceeds balance");

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override onlyWhenNotPaused returns (bool) {
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override notBlacklisted(sender) notBlacklisted(recipient) noSwapToDEX(recipient) onlyWhenNotPaused returns (bool) {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(_balances[sender] >= amount, "BEP20: transfer amount exceeds balance");
        require(_allowances[sender][msg.sender] >= amount, "BEP20: transfer amount exceeds allowance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    // --- Owner Control Functions ---
    function addToBlacklist(address account) external onlyOwner {
        require(account != address(0), "BEP20: cannot blacklist the zero address");
        _blacklist[account] = true;
        emit Transfer(address(0), account, 0); // Log the blacklist event
    }

    function removeFromBlacklist(address account) external onlyOwner {
        require(account != address(0), "BEP20: cannot unblacklist the zero address");
        _blacklist[account] = false;
        emit Transfer(account, address(0), 0); // Log the unblacklist event
    }

    function addDEXRouter(address router) external onlyOwner {
        _isDEXRouter[router] = true;
        emit Transfer(address(0), router, 0); // Log the addition of a DEX router
    }

    function removeDEXRouter(address router) external onlyOwner {
        _isDEXRouter[router] = false;
        emit Transfer(router, address(0), 0); // Log the removal of a DEX router
    }

    // --- Pause/Unpause Functions ---
    function pause() external onlyOwner {
        _paused = true;
        emit Transfer(address(0), address(0), 0); // Log the contract being paused
    }

    function unpause() external onlyOwner {
        _paused = false;
        emit Transfer(address(0), address(0), 0); // Log the contract being unpaused
    }
}
