const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SimpleLendingPlatform", function () {
  let lendingPlatform;
  let borrower;
  let lender;

    beforeEach(async function () {
    const LendingPlatform = await ethers.getContractFactory("SimpleLendingPlatform");
    lendingPlatform = await LendingPlatform.deploy();
    await lendingPlatform.deployed();

    [borrower, lender] = await ethers.getSigners();
  });

  describe("Loan initiation", function () {
    it("Should initiate a loan request", async function () {
      const desiredAmount = ethers.utils.parseEther("1");
      const repaymentTerms = 30;
      const interestRate = 5;
      const liquidationThreshold = 80;

      await lendingPlatform.initiateLoanRequest(desiredAmount, repaymentTerms, interestRate, liquidationThreshold);

      const borrowerData = await lendingPlatform.borrowers(borrower.address);
      expect(borrowerData.desiredAmount).to.equal(desiredAmount);
      expect(borrowerData.repaymentTerms).to.equal(repaymentTerms);
      expect(borrowerData.isLoanApproved).to.be.false;
      // Add more assertions for other fields
    });

    // Add more tests for loan initiation
  });

  describe("Loan approval", function () {
    beforeEach(async function () {
      const desiredAmount = ethers.utils.parseEther("1");
      const repaymentTerms = 30;
      const interestRate = 5;
      const liquidationThreshold = 80;

      await lendingPlatform.initiateLoanRequest(desiredAmount, repaymentTerms, interestRate, liquidationThreshold);
    });

    it("Should approve a loan", async function () {
      await lendingPlatform.approveLoan(borrower.address);

      const borrowerData = await lendingPlatform.borrowers(borrower.address);
      expect(borrowerData.isLoanApproved).to.be.true;
      // Add more assertions for other fields
    });

    // Add more tests for loan approval
  });

  describe("Loan rejection", function () {
    beforeEach(async function () {
      const desiredAmount = ethers.utils.parseEther("1");
      const repaymentTerms = 30;
      const interestRate = 5;
      const liquidationThreshold = 80;
  
      await lendingPlatform.initiateLoanRequest(desiredAmount, repaymentTerms, interestRate, liquidationThreshold);
    });
  
    it("Should reject a loan", async function () {
      await lendingPlatform.rejectLoan(borrower.address);
  
      const borrowerData = await lendingPlatform.borrowers(borrower.address);
      expect(borrowerData.isLoanApproved).to.be.false;
      // Add more assertions for other fields
    });
  
    // Add more tests for loan rejection
  });
  
  describe("Investment in loan", function () {
    beforeEach(async function () {
      const desiredAmount = ethers.utils.parseEther("1");
      const repaymentTerms = 30;
      const interestRate = 5;
      const liquidationThreshold = 80;
  
      await lendingPlatform.initiateLoanRequest(desiredAmount, repaymentTerms, interestRate, liquidationThreshold);
      await lendingPlatform.approveLoan(borrower.address);
    });
  
    it("Should allow a lender to invest in an approved loan", async function () {
      const percentage = 50;
      const investedAmount = ethers.utils.parseEther("0.5");
  
      await lendingPlatform.connect(lender).investInLoan(borrower.address, percentage, { value: investedAmount });
  
      const lenderInvestment = await lendingPlatform.lenderInvestments(lender.address);
      expect(lenderInvestment).to.equal(investedAmount);
      // Add more assertions for other fields
    });
  
    // Add more tests for investment in loan
  });
  
  // Add more test suites for other functions and scenarios

  // Add more test suites for other functions and scenarios

});