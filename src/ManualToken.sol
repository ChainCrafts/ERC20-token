// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;

/**
 * @title MANUAL ERC20 TOKEN IMPLEMENTATION
 * @dev step by step implementation of ERC20 standard
 */
contract ManualToken {
    // ============================================
    // STATE VARIABLES
    // ============================================
    string private _name;
    string private _symbol;
    uint8 private _decimal;

    //Total Supply tracker
    uint256 private _totalSupply;

    //Balance Mapping : address => balance
    mapping(address => uint256 balance) private _balances;

    //Allowance Mapping : owner => spender => amount
    mapping(address => mapping(address => uint256)) private _allowances;

    // ============================================
    // EVENTS (Required by ERC20 Standard)
    // ============================================
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // ============================================
    // CONSTRUCTOR
    // ============================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimal = 18; //Standard is 18 decimals

        // Mint initial supply to deployer
        _mint(msg.sender, 1000000 * 10 ** 18); // 1 million tokens
    }

    // ============================================
    // VIEW FUNCTIONS (ERC20 Standard)
    // ============================================

    /**
     * @dev Returns the name of the token
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns symbol of the token
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the total supply of the tokens
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the balence of an account
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Return the allowance one address has given another
     */
    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    // ============================================
    // PUBLIC FUNCTIONS (ERC20 Standard)
    // ============================================

    /**
     * @dev Transfers tokens from caller to recipient
     * @param to The recipient address
     * @param amount The amount to transfer
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev Approves a spender to spend tokens on behalf of caller
     * @param spender The address authorized to spend
     * @param amount The maximum amount they can spend
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev transfer token from one address to another using allowance
     * @param from the address to transfer from
     * @param to the recipient address
     * @param amount the amount to transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        address spender = msg.sender;

        //check and update allowance
        _spendAllowance(from, spender, amount);

        _transfer(from, to, amount);

        return true;
    }

    // ============================================
    // INTERNAL FUNCTIONS (Core Logic)
    // ============================================

    /**
     * @dev internal transfer function, this is where the actual tranfer happens
     */
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: Transfer from the zero address");
        require(to != address(0), "ERC20: Transfer to the zero address");

        uint256 fromBalace = _balances[from];
        require(
            fromBalace >= amount,
            "ERC20: Transfer amount exceed the balance"
        );

        //Update balances
        unchecked {
            _balances[from] = fromBalace - amount;
            // Overflow not possible: amount <= fromBalance <= totalSupply
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    /**
     * @dev Internal mint function
     * creates new tokens and assigns them to an account
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to zero address");

        //increase total supple
        _totalSupply += amount;

        // Overflow not possible: balance + amount <= totalSupply + amount (checked above)
        unchecked {
            _balances[account] += amount;
        }

        //transfer from address(0) (minting)
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Internal burn function
     * Destroys tokens from an account
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(
            accountBalance >= amount,
            "ERC20: burn amount exceeds the account balance"
        );

        //Update balances
        unchecked {
            _balances[account] -= amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply
            _totalSupply -= amount;
        }
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Internal approve function
     * Sets allowance for a spender
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        //Set allowance
        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Internal function to spend allowance
     * Reduces the allowance when transferFrom is called
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        //if allowance is not unlimited
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    // ============================================
    // OPTIONAL: Additional useful functions
    // ============================================
    /**
     * @dev increase allowance granted to a sender
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev decrease allowance granted to a sender
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "decreased allowance below 0"
        );
        unchecked {
            _approve(
                owner,
                spender,
                allowance(owner, spender) - subtractedValue
            );
        }
        return true;
    }
}
