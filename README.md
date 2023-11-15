# MavenBuilders
# Telos hackathon project.

# This is the idea behind the smart contract, due to time constraints we could not implement all the functionalities:

Welcome to our cutting-edge decentralized lending platform, where transparency, security, and efficiency converge through the power of a robust and secure smart contract operating on Ethereum Virtual Machine (EVM) compatible networks. This platform is designed to revolutionize lending and borrowing processes, seamlessly connecting borrowers and lenders while prioritizing security, gas optimization, simplicity, risk management, and collateral management.

# Section 1: Loan Creation
# Part 1.1: Borrower Initiates Loan Request
User Input:
Borrowers kick off the loan creation process by furnishing personal details, including legal name, address, and KYC information. Simultaneously, borrowers define loan parameters such as the desired amount, proposed interest rate, repayment terms, and the type of collateral.

KYC Verification:
Thorough KYC verification is conducted by the smart contract to ensure the borrower's identity. Secure key management safeguards sensitive KYC data. This process involves validating identification documents, regulatory compliance checks, and confirming the borrower's eligibility.

Collateral Validation:
The smart contract verifies the authenticity and eligibility of the provided collateral, maintaining the platform's standards and security.

# Part 1.2: Smart Contract Verification
Risk Management Criteria:
A comprehensive set of risk management criteria evaluates the loan request, assessing creditworthiness, debt-to-income ratios, and historical repayment behavior to align with the platform's risk tolerance.

Loan Approval Process:
Upon successful verification, the smart contract approves the loan request, generating a unique identifier and creating a transparent and immutable loan asset on the blockchain.

Metadata Storage:
Detailed loan terms, including repayment schedules and collateral information, are securely stored in the asset's metadata for easy access, transparency, and compliance.

Security and Gas Optimization Enhancements:
Rigorous security audits, multi-signature approval, gas optimization techniques, access controls, and encryption are implemented to fortify the smart contract.

# Section 2: Loan Investment
# Part 2.1: Lender Participation
Loan Asset Information:
Lenders access comprehensive information about available loan assets, borrower profiles, risk metrics, and historical performance data, enabling informed investment decisions.

Platform Investment Limits:
Smart contracts verify that proposed investments adhere to platform-specific limits, ensuring fair and balanced distribution among lenders.

# Part 2.2: Investment Process
Funds Transfer:
Lenders initiate the investment process by transferring funds in supported cryptocurrency, prioritizing gas optimization to minimize transaction costs.

Investment Limits Check:
The smart contract rigorously checks proposed investment amounts against predefined limits to prevent excessive investments and maintain platform stability.

# Part 2.3: Loan Token Minting
Token Generation:
Upon successful transfer, the smart contract mints loan tokens for lenders, ensuring fair and transparent ownership distribution.

Token Deposit:
Minted loan tokens are deposited directly into the lender's wallet, simplifying tracking and enabling easy withdrawal or trading.

Security and Gas Optimization Enhancements:
Secure fund transfer channels, gas optimization, and rate-limiting mechanisms are integrated for secure and efficient transactions.

# Section 3: Loan Repayment
# Part 3.1: Borrower Repayment
Repayment Schedule:
Borrowers adhere to a predefined repayment schedule, automating the deduction of repayments from their wallet to minimize the risk of missed payments.

# Part 3.2: Distribution of Repayments
Accurate Calculation:
Precise algorithms calculate repayment amounts, ensuring fair distribution among lenders by considering interest, outstanding principal, and additional fees.

Real-time Updates:
Lenders receive real-time updates on accrued interest and remaining repayments, fostering transparency and trust.

# Part 3.3: Withdrawal Option
Withdrawal Request:
Lenders can initiate withdrawal requests at any time, allowing flexibility in managing funds based on market conditions or personal preferences.

Flexible Withdrawal:
Withdrawal requests are processed promptly, transferring cryptocurrency directly to the lender's wallet for maximum flexibility.

Security and Gas Optimization Enhancements:
Secure channels for automated repayments, gas optimization, and event-driven mechanisms for real-time updates enhance security and reduce transaction costs.

# Section 4: Collateral Management
# Part 4.1: Collateral Storage
Decentralized Vault:
Borrower collateral is securely stored in a decentralized vault, managed by the smart contract, mitigating the risk of a single point of failure.

# Part 4.2: Value Monitoring
Real-time Monitoring:
Continuous real-time monitoring of collateral market value ensures accurate and up-to-date valuation through decentralized oracles.

Automated Alerts:
Automated alerts are generated when the collateral's value approaches predefined thresholds, serving as an early warning system.

# Part 4.3: Liquidation Trigger
Threshold Evaluation:
Regular evaluation against predefined thresholds triggers the collateral liquidation process to protect lenders' interests.

Market Value Liquidation:
During liquidation, the smart contract sells collateral at current market value, using funds obtained to repay the outstanding loan amount for a fair and efficient debt recovery process.

Security and Gas Optimization Enhancements:
Access controls, encryption, decentralized storage solutions, and gas optimization techniques are implemented for enhanced collateral security, resilience, and efficient execution of liquidation processes.

In conclusion, this decentralized lending platform encompasses a comprehensive and secure ecosystem, offering borrowers and lenders a transparent, efficient, and trustworthy environment for financial interactions. The integration of cutting-edge technologies and best practices ensures a robust and resilient system that sets a new standard for decentralized finance.

# Here is a detailed description of what the smart contract wants to accomplish:

The code is a Solidity smart contract written for a simple lending platform. It allows borrowers to initiate loan requests and lenders to invest in approved loans. Here's a breakdown of the contract's main components:

# Structs:
Borrower: Stores information about a borrower, including the desired loan amount, repayment terms, loan approval status, collateral amount, collateral token address, interest rate, liquidation threshold, last repayment time, and borrowed amount.
LoanApplication: Represents a loan application, containing the borrower's address, desired loan amount, approval and rejection counts, repayment terms, liquidation threshold, and mappings for approvals and rejections.

# Mappings:
borrowers: Maps borrower addresses to Borrower structs.
lastActionTime: Maps addresses to the timestamp of their last action.
lenderInvestments: Maps lender addresses to their invested amount.
lenderWithdrawalTime: Maps lender addresses to the timestamp of their last withdrawal.
whitelistedInvestors: Maps investor addresses to their whitelisting status.
whitelistedLiquidators: Maps liquidator addresses to their whitelisting status.
loanApplications: Maps borrower addresses to their loan applications.


# Events:
LoanInitiated: Triggered when a loan request is initiated.
LoanApproved: Triggered when a loan is approved.
LoanRejected: Triggered when a loan is rejected.
LoanInvested: Triggered when a lender invests in a loan.
LoanRepaid: Triggered when a loan is fully repaid.
PartialLoanRepaid: Triggered when a partial loan repayment is made.
LenderWithdrawsInvestment: Triggered when a lender withdraws their investment.
CollateralSeized: Triggered when collateral is seized from a defaulted loan.
Liquidation: Triggered when a loan is liquidated.
CollateralAdded: Triggered when collateral is added to an approved loan.
InvestmentWithdrawn: Triggered when a lender withdraws their investment.
WhitelistedInvestorAdded: Triggered when an investor is added to the whitelist.
WhitelistedInvestorRemoved: Triggered when an investor is removed from the whitelist.
WhitelistedLiquidatorAdded: Triggered when a liquidator is added to the whitelist.
WhitelistedLiquidatorRemoved: Triggered when a liquidator is removed from the whitelist.
CircuitBreakerActivated: Triggered when the circuit breaker is activated.
CircuitBreakerDeactivated: Triggered when the circuit breaker is deactivated.

# Modifiers:
onlyBorrower: Checks if the caller is a valid borrower.
onlyApprovedLoan: Checks if the loan is approved for a specific borrower.
rateLimited: Implements rate limiting for actions.
lockupPeriod: Enforces a lock-up period for lender withdrawals.
onlyWhitelistedInvestor: Checks if the caller is a whitelisted investor.
onlyWhitelistedLiquidator: Checks if the caller is a whitelisted liquidator.
flashLoanProtection: Implements flash loan protection.
circuitBreakerCheck: Checks if the circuit breaker is active.

# Functions:
initiateLoanRequest: Allows borrowers to initiate a loan request.
approveLoan: Allows the contract owner to approve a loan for a borrower.
rejectLoan: Allows the contract owner to reject a loan for a borrower.
investInLoan: Allows whitelisted investors to invest in an approved loan.
repayLoan: Allows borrowers to fully repay their loan.
repayPartialLoan: Allows borrowers to make a partial repayment of their loan.
withdrawInvestment: Allows lenders to withdraw their investment after the lock-up period.
seizeCollateral: Allows whitelisted liquidators to seize collateral from a defaulted loan.
liquidateLoan: Allows whitelisted liquidators to liquidate a loan.
addCollateral: Allows borrowers to add collateral to an approved loan.
pause: Pauses the contract.
unpause: Unpauses the contract.
calculateInterest: Calculates the interest amount based on the loan amount and interest rate.
calculatePenalty: Calculates the penalty amount based on the collateral amount.
calculateLiquidationAmount: Calculates the liquidation amount based on the collateral amount.
isFlashLoan: Checks if a flash loan has occurred.
isFlashLoanProtectionValid: Checks if the flash loan protection is valid.
setFlashLoanProtection: Enables or disables flash loan protection.
setCircuitBreaker: Enables or disables the circuit breaker.
isContractPaused: Checks if the contract is currently paused.
isFlashLoanProtectionEnabled: Checks if flash loan protection is enabled.
