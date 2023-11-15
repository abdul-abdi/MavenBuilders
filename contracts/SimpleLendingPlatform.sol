// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract SimpleLendingPlatform is Ownable(msg.sender), ReentrancyGuard, Pausable {
    struct Borrower {
        uint256 desiredAmount;
        uint256 repaymentTerms;
        bool isLoanApproved;
        uint256 collateralAmount;
        address collateralTokenAddress;
        uint256 interestRate;
        uint256 liquidationThreshold;
        uint256 lastRepaymentTime;
        uint256 borrowedAmount; // New field to store the amount borrowed
    }

    struct LoanApplication {
        address borrower;
        uint256 desiredAmount;
        uint256 approvalCount;
        uint256 rejectionCount;
        uint256 repaymentTerms; // Add the repaymentTerms field
        uint256 liquidationThreshold; // Add the liquidationThreshold field
        mapping(address => bool) approvals;
        mapping(address => bool) rejections;
    }
    

    mapping(address => Borrower) public borrowers;
    mapping(address => uint256) public lastActionTime;
    mapping(address => uint256) public lenderInvestments;
    mapping(address => uint256) public lenderWithdrawalTime;
    mapping(address => bool) public whitelistedInvestors;
    mapping(address => bool) public whitelistedLiquidators;
    mapping(address => LoanApplication) public loanApplications; // New mapping to store loan applications

    bool private isPaused;
    bool private flashLoanProtectionEnabled;
    bool private circuitBreaker;

    event LoanInitiated(address indexed borrower, uint256 desiredAmount, uint256 repaymentTerms, uint256 interestRate, uint256 liquidationThreshold);
    event LoanApproved(address indexed borrower);
    event LoanRejected(address indexed borrower); // New event for loan rejection
    event LoanInvested(address indexed lender, address indexed borrower, uint256 investedAmount, uint256 interestRate, uint256 liquidationThreshold);
    event LoanRepaid(address indexed borrower, uint256 repaymentAmount, uint256 remainingAmount);
    event PartialLoanRepaid(address indexed borrower, uint256 repaymentAmount);
    event LenderWithdrawsInvestment(address indexed lender, uint256 withdrawalAmount);
    event CollateralSeized(address indexed borrower, address indexed liquidator, uint256 collateralAmount, uint256 penaltyAmount, address collateralTokenAddress);
    event Liquidation(address indexed borrower, address indexed liquidator, uint256 collateralAmount, uint256 liquidationAmount);
    event CollateralAdded(address indexed borrower, uint256 addedCollateral);
    event InvestmentWithdrawn(address indexed lender, uint256 withdrawalAmount);
    event WhitelistedInvestorAdded(address indexed investor);
    event WhitelistedInvestorRemoved(address indexed investor);
    event WhitelistedLiquidatorAdded(address indexed liquidator);
    event WhitelistedLiquidatorRemoved(address indexed liquidator);
    event CircuitBreakerActivated(address indexed owner);
    event CircuitBreakerDeactivated(address indexed owner);

    modifier onlyBorrower() {
        require(borrowers[msg.sender].desiredAmount > 0, "Not a valid borrower");
        _;
    }

    modifier onlyApprovedLoan(address borrowerAddress) {
        require(borrowers[borrowerAddress].isLoanApproved, "Loan not approved for this borrower");
        _;
    }

    modifier rateLimited() {
        require(lastActionTime[msg.sender] + 1 minutes < block.timestamp, "Rate limited");
        lastActionTime[msg.sender] = block.timestamp;
        _;
    }

    modifier lockupPeriod() {
        require(lenderWithdrawalTime[msg.sender] + 7 days < block.timestamp, "Lock-up period not passed");
        _;
    }

    modifier onlyWhitelistedInvestor() {
        require(whitelistedInvestors[msg.sender], "Not a whitelisted investor");
        _;
    }

    modifier onlyWhitelistedLiquidator() {
        require(whitelistedLiquidators[msg.sender], "Not a whitelisted liquidator");
        _;
    }

    modifier flashLoanProtection() {
        require(!flashLoanProtectionEnabled || isFlashLoanProtectionValid(), "Flash loan protection triggered");
        _;
    }

    modifier circuitBreakerCheck() {
        require(!circuitBreaker, "Contract is paused due to suspicious activity");
        _;
    }

    constructor() {
        isPaused = false;
        flashLoanProtectionEnabled = true;
        circuitBreaker = false;
    }

    /**
     * @dev Initiates a loan request and triggers the voting process.
     * @param _desiredAmount The desired loan amount.
     * @param _repaymentTerms The repayment terms in days.
     * @param _interestRate The interest rate in percentage.
     * @param _liquidationThreshold The collateral liquidation threshold in percentage.
     */

    
    function initiateLoanRequest(uint256 _desiredAmount, uint256 _repaymentTerms, uint256 _interestRate, uint256 _liquidationThreshold) external
        whenNotPaused
        rateLimited
        circuitBreakerCheck
        flashLoanProtection
    {
        require(_desiredAmount > 0, "Desired amount must be greater than 0");
        require(_repaymentTerms > 0, "Repayment terms must be greater than 0");
        require(_interestRate > 0, "Interest rate must be greater than 0");
        require(_liquidationThreshold > 0, "Liquidation threshold must be greater than 0");
        require(borrowers[msg.sender].desiredAmount == 0, "Borrower already exists");

        // Create a new LoanApplication struct
        LoanApplication storage loanApplication = loanApplications[msg.sender];
        loanApplication.borrower = msg.sender;
        loanApplication.desiredAmount = _desiredAmount;
        loanApplication.approvalCount = 0;
        loanApplication.rejectionCount = 0;


        emit LoanInitiated(msg.sender, _desiredAmount, _repaymentTerms, _interestRate, _liquidationThreshold);
    }

    /**
     * @dev Approves a loan for a borrower.
     * @param borrowerAddress The address of the borrower.
     */
    function approveLoan(address borrowerAddress) external onlyOwner whenNotPaused circuitBreakerCheck {
        LoanApplication storage loanApplication = loanApplications[borrowerAddress];
        require(loanApplication.desiredAmount > 0 && loanApplication.approvalCount > loanApplication.rejectionCount, "Invalid loan approval");

        Borrower storage borrower = borrowers[borrowerAddress];
        borrower.desiredAmount = loanApplication.desiredAmount;
        borrower.repaymentTerms = loanApplication.repaymentTerms;
        borrower.isLoanApproved = true;
        borrower.interestRate = loanApplication.desiredAmount;
        borrower.liquidationThreshold = loanApplication.liquidationThreshold;

        emit LoanApproved(borrowerAddress);
    }

    /**
     * @dev Rejects a loan for a borrower.
     * @param borrowerAddress The address of the borrower.
     */
    function rejectLoan(address borrowerAddress) external onlyOwner whenNotPaused circuitBreakerCheck {
        LoanApplication storage loanApplication = loanApplications[borrowerAddress];
        require(loanApplication.desiredAmount > 0 && loanApplication.rejectionCount > loanApplication.approvalCount, "Invalid loan rejection");

        delete loanApplications[borrowerAddress];

        emit LoanRejected(borrowerAddress);
    }

    /**
     * @dev Allows a lender to invest in an approved loan with a specified percentage.
     * @param borrowerAddress The address of the borrower.
     * @param percentage The percentage of the desired loan amount to invest.
     */
    function investInLoan(address borrowerAddress, uint256 percentage) external payable whenNotPaused nonReentrant rateLimited onlyWhitelistedInvestor circuitBreakerCheck {
        require(!isFlashLoan(), "Flash loan protection triggered");
        Borrower storage borrower = borrowers[borrowerAddress];
        require(borrower.isLoanApproved && lenderInvestments[msg.sender] == 0, "Invalid investment");
        require(percentage > 0 && percentage <= 100, "Invalid percentage");

        uint256 investedAmount = borrower.desiredAmount * percentage / 100;
        require(msg.value == investedAmount, "Investment amount does not match percentage");

        lenderInvestments[msg.sender] = investedAmount;
        borrower.borrowedAmount += investedAmount;

        emit LoanInvested(msg.sender, borrowerAddress, investedAmount, borrower.interestRate, borrower.liquidationThreshold);
    }

    /**
     * @dev Repays the loan in full.
     */
    function repayLoan() external payable onlyBorrower whenNotPaused nonReentrant rateLimited circuitBreakerCheck {
        Borrower storage borrower = borrowers[msg.sender];
        require(borrower.isLoanApproved && msg.value >= borrower.desiredAmount, "Invalid repayment");
        require(msg.value <= borrower.desiredAmount, "Repayment amount exceeds outstanding loan amount");

        borrower.isLoanApproved = false;
        borrower.desiredAmount = 0;
        borrower.lastRepaymentTime = block.timestamp;

        uint256 interest = calculateInterest(msg.value, borrower.interestRate);
        uint256 remainingAmount = msg.value - interest;

        if (borrower.collateralAmount > 0) {
            require(ERC20(borrower.collateralTokenAddress).totalSupply() > 0, "Invalid ERC20 token");
            ERC20(borrower.collateralTokenAddress).transfer(msg.sender, borrower.collateralAmount);
        }

        emit LoanRepaid(msg.sender, msg.value, remainingAmount);
    }

    /**
     * @dev Repays a partial amount of the loan.
     * @param _repaymentAmount The amount to be repaid.
     */
    function repayPartialLoan(uint256 _repaymentAmount) external payable onlyBorrower whenNotPaused nonReentrant rateLimited circuitBreakerCheck {
        Borrower storage borrower = borrowers[msg.sender];
        require(borrower.isLoanApproved && _repaymentAmount > 0 && _repaymentAmount < borrower.desiredAmount, "Invalid partial repayment");
        require(_repaymentAmount <= lenderInvestments[msg.sender], "Repayment amount exceeds lender's investment");

        uint256 interest = calculateInterest(_repaymentAmount, borrower.interestRate);
        uint256 remainingAmount = _repaymentAmount - interest;

        borrower.desiredAmount = borrower.desiredAmount - _repaymentAmount;
        borrower.lastRepaymentTime = block.timestamp;

        if (borrower.collateralAmount > 0) {
            require(ERC20(borrower.collateralTokenAddress).totalSupply() > 0, "Invalid ERC20 token");
            ERC20(borrower.collateralTokenAddress).transfer(msg.sender, borrower.collateralAmount);
        }

        emit PartialLoanRepaid(msg.sender, remainingAmount);
    }

    /**
     * @dev Allows a lender to withdraw their investment after the lock-up period.
     */
    function withdrawInvestment() external lockupPeriod whenNotPaused nonReentrant rateLimited circuitBreakerCheck {
        uint256 investment = lenderInvestments[msg.sender];
        require(investment > 0, "No investment to withdraw");
        require(block.timestamp - lenderWithdrawalTime[msg.sender] >= 7 days, "Withdrawal not allowed within 7 days");

        lenderInvestments[msg.sender] = 0;
        lenderWithdrawalTime[msg.sender] = block.timestamp;

        // Use the Withdraw pattern for safe withdrawals
        (bool success, ) = msg.sender.call{value: investment}("");
        require(success, "Withdrawal failed");

        emit InvestmentWithdrawn(msg.sender, investment);
    }

    /**
     * @dev Seizes collateral from a defaulted loan.
     * @param borrowerAddress The address of the borrower.
     * @param _collateralAmount The amount of collateral to be seized.
     */
    function seizeCollateral(address borrowerAddress, uint256 _collateralAmount) external onlyWhitelistedLiquidator whenNotPaused nonReentrant rateLimited circuitBreakerCheck {
        Borrower storage borrower = borrowers[borrowerAddress];
        require(borrower.desiredAmount > 0, "No defaulted loan");
        require(block.timestamp >= borrower.lastRepaymentTime + 1 days, "Grace period not elapsed");
        require(_collateralAmount > 0, "Seized collateral must be greater than 0");
        require(_collateralAmount <= borrower.collateralAmount, "Seized collateral exceeds borrower's deposit");

        require(ERC20(borrower.collateralTokenAddress).totalSupply() > 0, "Invalid ERC20 token");
        ERC20(borrower.collateralTokenAddress).transferFrom(msg.sender, address(this), _collateralAmount);

        borrower.collateralAmount = borrower.collateralAmount - _collateralAmount;

        emit CollateralSeized(borrowerAddress, msg.sender, _collateralAmount, calculatePenalty(_collateralAmount), borrower.collateralTokenAddress);
    }

    /**
     * @dev Liquidates a loan if the collateral amount is below the liquidation threshold.
     * @param borrowerAddress The address of the borrower.
     */
    function liquidateLoan(address borrowerAddress) external onlyWhitelistedLiquidator whenNotPaused nonReentrant rateLimited circuitBreakerCheck {
        Borrower storage borrower = borrowers[borrowerAddress];
        require(borrower.desiredAmount > 0 && borrower.isLoanApproved, "Invalid loan for liquidation");
        require(borrower.collateralAmount > 0, "No collateral to liquidate");
        require(borrower.collateralAmount >= borrower.liquidationThreshold, "Collateral below liquidation threshold");

        require(ERC20(borrower.collateralTokenAddress).totalSupply() > 0, "Invalid ERC20 token");
        uint256 liquidationAmount = calculateLiquidationAmount(borrower.collateralAmount);
        require(liquidationAmount <= borrower.collateralAmount, "Liquidation amount exceeds collateral amount");

        borrower.isLoanApproved = false;
        borrower.desiredAmount = 0;
        borrower.collateralAmount = 0;

        // Use the Withdraw pattern for safe withdrawals
        (bool success, ) = msg.sender.call{value: liquidationAmount}("");
        require(success, "Liquidation failed");

        emit Liquidation(borrowerAddress, msg.sender, borrower.collateralAmount, liquidationAmount);
    }

    /**
     * @dev Adds collateral to an approved loan.
     * @param _collateralAmount The amount of collateral to be added.
     */
    function addCollateral(uint256 _collateralAmount) external onlyBorrower whenNotPaused nonReentrant rateLimited circuitBreakerCheck {
        Borrower storage borrower = borrowers[msg.sender];
        require(borrower.isLoanApproved, "Loan not approved");
        require(_collateralAmount > 0, "Collateral amount must be greater than 0");

        require(ERC20(borrower.collateralTokenAddress).totalSupply() > 0, "Invalid ERC20 token");
        ERC20(borrower.collateralTokenAddress).transferFrom(msg.sender, address(this), _collateralAmount);

        borrower.collateralAmount = borrower.collateralAmount + _collateralAmount;

        emit CollateralAdded(msg.sender, _collateralAmount);
    }

    /**
     * @dev Pauses the contract.
     */
    function pause() external onlyOwner {
        isPaused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract.
     */
    function unpause() external onlyOwner {
        isPaused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Calculates the interest amount based on the loan amount and interest rate.
     * @param _amount The loan amount.
     * @param _interestRate The interest rate.
     * @return The calculated interest amount.
     */
    function calculateInterest(uint256 _amount, uint256 _interestRate) internal pure returns (uint256) {
        return _amount * _interestRate / (100);
    }

    /**
     * @dev Calculates the penalty amount based on the collateral amount.
     * @param _collateralAmount The collateral amount.
     * @return The calculated penalty amount.
     */
    function calculatePenalty(uint256 _collateralAmount) internal pure returns (uint256) {
        // Arbitrary penalty calculation, can be adjusted based on the use case
        return _collateralAmount * 10 / 100;
    }

    /**
     * @dev Calculates the liquidation amount based on the collateral amount.
     * @param _collateralAmount The collateral amount.
     * @return The calculated liquidation amount.
     */
    function calculateLiquidationAmount(uint256 _collateralAmount) internal pure returns (uint256) {
        // Arbitrary liquidation amount calculation, can be adjusted based on the use case
        return _collateralAmount * 90 / 100;
    }

    /**
     * @dev Checks if a flash loan has occurred by comparing the contract's balance before and after the function execution.
     * @return A boolean indicating whether a flash loan has occurred.
     */
    function isFlashLoan() internal view returns (bool) {
        uint256 contractBalanceBefore = address(this).balance;
        // Perform a dummy operation that consumes gas
        uint256 contractBalanceAfter = address(this).balance;
        return contractBalanceAfter < contractBalanceBefore;
    }

    /**
     * @dev Checks if the flash loan protection is valid.
     * @return A boolean indicating whether the flash loan protection is valid.
     */
    function isFlashLoanProtectionValid() internal view returns (bool) {
        return msg.sender == tx.origin && tx.origin == tx.origin;
    }

    /**
     * @dev Enables or disables flash loan protection.
     * @param _enabled A boolean indicating whether to enable or disable flash loan protection.
     */
    function setFlashLoanProtection(bool _enabled) external onlyOwner {
        flashLoanProtectionEnabled = _enabled;
    }

    /**
     * @dev Enables or disables the circuit breaker.
     * @param _enabled A boolean indicating whether to enable or disable the circuit breaker.
     */
    function setCircuitBreaker(bool _enabled) external onlyOwner {
        circuitBreaker = _enabled;
        if (_enabled) {
            emit CircuitBreakerActivated(msg.sender);
        } else {
            emit CircuitBreakerDeactivated(msg.sender);
        }
    }

    /**
     * @dev Checks if the contract is currently paused.
     * @return A boolean indicating whether the contract is paused.
     */
    function isContractPaused() external view returns (bool) {
        return isPaused || circuitBreaker;
    }

    /**
     * @dev Checks if flash loan protection is enabled.
     * @return A boolean indicating whether flash loan protection is enabled.
     */
    function isFlashLoanProtectionEnabled() external view returns (bool) {
        return flashLoanProtectionEnabled;
    }

    // Rest of the contract code...

}