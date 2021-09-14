USE H_Accounting;

####################################################################################################################################
# PROCEDURE CREATION - Please change the name of the procedure if it doesn't run
####################################################################################################################################

# Profit-Loss Statement
DROP PROCEDURE IF EXISTS `team9_profit_loss`;

DELIMITER $$
CREATE PROCEDURE `team9_profit_loss`(varCalendarYear YEAR)
    BEGIN
		DECLARE varTotalRevenue DOUBLE PRECISION DEFAULT 0;
		DECLARE varTotalCOGS DOUBLE PRECISION DEFAULT 0;
        DECLARE varGrossProfit DOUBLE PRECISION DEFAULT 0;
		DECLARE varIncomeTaxes DOUBLE DEFAULT 0;
		DECLARE varOtherIncome DOUBLE DEFAULT 0;
        DECLARE varOtherExpenses DOUBLE DEFAULT 0;
        DECLARE varOtherTaxes DOUBLE DEFAULT 0;
        DECLARE varNetOperatingIncome DOUBLE DEFAULT 0;
        DECLARE varNetOtherIncome DOUBLE DEFAULT 0;
        
		SET @varTotalRevenue = (SELECT SUM(jeli.credit)
						FROM journal_entry_line_item 	AS jeli
							INNER JOIN account 				AS acc 		ON acc.account_id = jeli.account_id    
							INNER JOIN journal_entry 		AS je 		ON je.journal_entry_id = jeli.journal_entry_id
                        WHERE profit_loss_section_id = 68    
							AND YEAR(je.entry_date) = varCalendarYear
                            AND je.cancelled = 0
							AND je.debit_credit_balanced = 1 
						GROUP BY YEAR(je.entry_date));
                        
		SET @varTotalRevenueClean = (SELECT CASE WHEN @varTotalRevenue IS NULL or @varTotalRevenue = ' ' THEN 0 ELSE @varTotalRevenue END);

                            
        SET @varTotalCOGS = (SELECT SUM(jeli.debit)
						FROM journal_entry_line_item 	AS jeli
							INNER JOIN account 				AS acc 		ON acc.account_id = jeli.account_id    
							INNER JOIN journal_entry 		AS je 		ON je.journal_entry_id = jeli.journal_entry_id
                        WHERE profit_loss_section_id = 74    
							AND YEAR(je.entry_date) = varCalendarYear);
		
        SET @varTotalCOGSClean = (SELECT CASE WHEN @varTotalCOGS IS NULL or @varTotalCOGS = ' ' THEN 0 ELSE @varTotalCOGS END);
                            
		SET @varGrossProfit = @varTotalRevenueClean - @varTotalCOGSClean;
        
        SET @varIncomeTaxes = (SELECT SUM(jeli.debit)
						FROM journal_entry_line_item 	AS jeli
							INNER JOIN account 				AS acc 		ON acc.account_id = jeli.account_id    
							INNER JOIN journal_entry 		AS je 		ON je.journal_entry_id = jeli.journal_entry_id    
						WHERE profit_loss_section_id = 79
							AND YEAR(je.entry_date) = varCalendarYear
							AND je.cancelled = 0
							AND je.debit_credit_balanced = 1 
						GROUP BY YEAR(je.entry_date));
                        
		SET @varIncomeTaxesClean = (SELECT CASE WHEN @varIncomeTaxes IS NULL or @varIncomeTaxes = ' ' THEN 0 ELSE @varIncomeTaxes END);
                        
		SET @varNetOperatingProfitAfterTaxes = @varGrossProfit - @varIncomeTaxesClean;
        
        SET @varOtherIncome = (SELECT SUM(jeli.credit)
								FROM journal_entry_line_item 	AS jeli
									INNER JOIN account 				AS acc 		ON acc.account_id = jeli.account_id    
									INNER JOIN journal_entry 		AS je 		ON je.journal_entry_id = jeli.journal_entry_id    
								WHERE profit_loss_section_id = 78
									AND YEAR(je.entry_date) = varCalendarYear
									AND je.cancelled = 0
									AND je.debit_credit_balanced = 1 
								GROUP BY YEAR(je.entry_date));
                                
		SET @varOtherIncomeClean = (SELECT CASE WHEN @varOtherIncome IS NULL or @varOtherIncome = ' ' THEN 0 ELSE @varOtherIncome END);

                                
		SET @varOtherExpenses = ( SELECT SUM(jeli.credit)
									FROM journal_entry_line_item 	AS jeli
										INNER JOIN account 				AS acc 		ON acc.account_id = jeli.account_id    
										INNER JOIN journal_entry 		AS je 		ON je.journal_entry_id = jeli.journal_entry_id    
									WHERE profit_loss_section_id = 77
										AND YEAR(je.entry_date) = varCalendarYear
										AND je.cancelled = 0
										AND je.debit_credit_balanced = 1 
									GROUP BY YEAR(je.entry_date));
		
        SET @varOtherExpensesClean = (SELECT CASE WHEN @varOtherExpenses IS NULL or @varOtherExpenses = ' ' THEN 0 ELSE @varOtherExpenses END);
                            
		SET @varOtherTaxes = (SELECT SUM(jeli.debit)
								FROM journal_entry_line_item 	AS jeli
									INNER JOIN account 				AS acc		ON acc.account_id = jeli.account_id    
									INNER JOIN journal_entry 		AS je 		ON je.journal_entry_id = jeli.journal_entry_id    
								WHERE profit_loss_section_id = 80
									AND YEAR(je.entry_date) = varCalendarYear
									AND je.cancelled = 0
									AND je.debit_credit_balanced = 1 
								GROUP BY YEAR(je.entry_date));
                                
		SET @varOtherTaxesClean = (SELECT CASE WHEN @varOtherTaxes IS NULL or @varOtherTaxes = '' THEN 0 ELSE @varOtherTaxes END);
                                
		SET @varNetOtherIncome = @varOtherIncomeClean - @varOtherExpensesClean - @varOtherTaxesClean;
        
        SET @varNetIncome = @varNetOperatingProfitAfterTaxes + @varNetOtherIncome;
                            
		SELECT varCalendarYear as Year, 'PROFIT & LOSS STATEMENT' AS Item, '$' AS Balance
			FROM journal_entry 		AS je
			WHERE YEAR(je.entry_date) = varCalendarYear
        
        UNION
    
		SELECT '', 'Revenue', FORMAT(@varTotalRevenueClean, 2)
        
        UNION
        
        SELECT '', 'COGS', FORMAT(@varTotalCOGSClean,2) 
        
        UNION
        
        SELECT '', 'Gross Profit', FORMAT(@varGrossProfit, 2)
	
        UNION
        
        SELECT '', 'Income Taxes', FORMAT(@varIncomeTaxesClean,2) 
        
        UNION
        
        SELECT '', 'Net Operating Profit After Taxes', FORMAT(@varNetOperatingProfitAfterTaxes,2)
        
        UNION
        
        SELECT '', 'Other Income', FORMAT(@varOtherIncomeClean,2) 
        
        UNION
        
        SELECT '', 'Other Expenses', FORMAT(@varOtherExpensesClean,2)
        
        UNION
        
        SELECT '', 'Other Taxes', FORMAT(@varOtherTaxesClean,2)
        
        UNION
        
        SELECT '', 'Net Other Income', FORMAT(@varNetOtherIncome,2)
		
        UNION
        
		SELECT '', 'Net Income', FORMAT(@varNetIncome,2);
        
    END $$

DELIMITER ;	

# Balance Sheet
DROP PROCEDURE IF EXISTS `team9_balance_sheet`;

DELIMITER $$
CREATE PROCEDURE `team9_balance_sheet`(varCalendarYear YEAR)
    BEGIN
    
	DECLARE varNetOtherIncome DOUBLE DEFAULT 0;
    
    SET @varCAD = (SELECT SUM(jeli.debit)
							FROM journal_entry_line_item as jeli
								INNER JOIN account as acc on acc.account_id = jeli.account_id    
								INNER JOIN journal_entry as je on je.journal_entry_id = jeli.journal_entry_id    
							WHERE balance_sheet_section_id = 61    
								AND YEAR(je.entry_date) <= varCalendarYear
								AND (je.debit_credit_balanced) = 1
								AND (je.cancelled) = 0
							GROUP BY balance_sheet_section_id);
	
    SET @varCADClean = (SELECT CASE WHEN @varCAD IS NULL or @varCAD = ' ' THEN 0 ELSE @varCAD END);
    
    SET @varCAC = (SELECT SUM(jeli.credit)
							FROM journal_entry_line_item as jeli
								INNER JOIN account as acc on acc.account_id = jeli.account_id    
								INNER JOIN journal_entry as je on je.journal_entry_id = jeli.journal_entry_id    
							WHERE balance_sheet_section_id = 61    
								AND YEAR(je.entry_date) <= varCalendarYear
								AND (je.debit_credit_balanced) = 1
								AND (je.cancelled) = 0
							GROUP BY balance_sheet_section_id);
                            
	SET @varCACClean = (SELECT CASE WHEN @varCAC IS NULL or @varCAC = ' ' THEN 0 ELSE @varCAC END);
                            
	SET @varCA = @varCADClean - @varCACClean;
                            
	SET @varFAD = (SELECT SUM(jeli.debit)
							FROM journal_entry_line_item as jeli
								INNER JOIN account as acc on acc.account_id = jeli.account_id    
								INNER JOIN journal_entry as je on je.journal_entry_id = jeli.journal_entry_id    
							WHERE balance_sheet_section_id = 62    
								AND YEAR(je.entry_date) <= varCalendarYear
								AND (je.debit_credit_balanced) = 1
								AND (je.cancelled) = 0
							GROUP BY balance_sheet_section_id);
	
    SET @varFADClean = (SELECT CASE WHEN @varFAD IS NULL or @varFAD = ' ' THEN 0 ELSE @varFAD END);
    
    SET @varFAC = (SELECT SUM(jeli.credit)
							FROM journal_entry_line_item as jeli
								INNER JOIN account as acc on acc.account_id = jeli.account_id    
								INNER JOIN journal_entry as je on je.journal_entry_id = jeli.journal_entry_id    
							WHERE balance_sheet_section_id = 62    
								AND YEAR(je.entry_date) <= varCalendarYear
								AND (je.debit_credit_balanced) = 1
								AND (je.cancelled) = 0
							GROUP BY balance_sheet_section_id);
                            
	SET @varFACClean = (SELECT CASE WHEN @varFAC IS NULL or @varFAC = ' ' THEN 0 ELSE @varFAC END);
                            
	SET @varFA = @varFADClean - @varFACClean;
    
    SET @varDAD = (SELECT SUM(jeli.debit)
							FROM journal_entry_line_item as jeli
								INNER JOIN account as acc on acc.account_id = jeli.account_id    
								INNER JOIN journal_entry as je on je.journal_entry_id = jeli.journal_entry_id    
							WHERE balance_sheet_section_id = 63    
								AND YEAR(je.entry_date) <= varCalendarYear
								AND (je.debit_credit_balanced) = 1
								AND (je.cancelled) = 0
							GROUP BY balance_sheet_section_id);
	
    SET @varDADClean = (SELECT CASE WHEN @varDAD IS NULL or @varDAD = ' ' THEN 0 ELSE @varDAD END);
    
    SET @varDAC = (SELECT SUM(jeli.credit)
							FROM journal_entry_line_item as jeli
								INNER JOIN account as acc on acc.account_id = jeli.account_id    
								INNER JOIN journal_entry as je on je.journal_entry_id = jeli.journal_entry_id    
							WHERE balance_sheet_section_id = 63    
								AND YEAR(je.entry_date) <= varCalendarYear
								AND (je.debit_credit_balanced) = 1
								AND (je.cancelled) = 0
							GROUP BY balance_sheet_section_id);
                            
	SET @varDACClean = (SELECT CASE WHEN @varDAC IS NULL or @varDAC = ' ' THEN 0 ELSE @varDAC END);
                            
	SET @varDA = @varDADClean - @varDACClean;
    
	SET @varTotalAssets = @varCA + @varFA + @varDA;
    
    SET @varCLD = (SELECT SUM(jeli.debit)
							FROM journal_entry_line_item as jeli
								INNER JOIN account as acc on acc.account_id = jeli.account_id    
								INNER JOIN journal_entry as je on je.journal_entry_id = jeli.journal_entry_id    
							WHERE balance_sheet_section_id = 64    
								AND YEAR(je.entry_date) <= varCalendarYear
								AND (je.debit_credit_balanced) = 1
								AND (je.cancelled) = 0
							GROUP BY balance_sheet_section_id);
	
    SET @varCLDClean = (SELECT CASE WHEN @varCLD IS NULL or @varCLD = ' ' THEN 0 ELSE @varCLD END);
    
    SET @varCLC = (SELECT SUM(jeli.credit)
							FROM journal_entry_line_item as jeli
								INNER JOIN account as acc on acc.account_id = jeli.account_id    
								INNER JOIN journal_entry as je on je.journal_entry_id = jeli.journal_entry_id    
							WHERE balance_sheet_section_id = 64    
								AND YEAR(je.entry_date) <= varCalendarYear
								AND (je.debit_credit_balanced) = 1
								AND (je.cancelled) = 0
							GROUP BY balance_sheet_section_id);
                            
	SET @varCLCClean = (SELECT CASE WHEN @varCLC IS NULL or @varCLC = ' ' THEN 0 ELSE @varCLC END);
                            
	SET @varCL = @varCLCClean - @varCLDClean;
    
    SET @varLTLD = (SELECT SUM(jeli.debit)
							FROM journal_entry_line_item as jeli
								INNER JOIN account as acc on acc.account_id = jeli.account_id    
								INNER JOIN journal_entry as je on je.journal_entry_id = jeli.journal_entry_id    
							WHERE balance_sheet_section_id = 65    
								AND YEAR(je.entry_date) <= varCalendarYear
								AND (je.debit_credit_balanced) = 1
								AND (je.cancelled) = 0
							GROUP BY balance_sheet_section_id);
	
    SET @varLTLDClean = (SELECT CASE WHEN @varLTLD IS NULL or @varLTLD = ' ' THEN 0 ELSE @varLTLD END);
    
    SET @varLTLC = (SELECT SUM(jeli.credit)
							FROM journal_entry_line_item as jeli
								INNER JOIN account as acc on acc.account_id = jeli.account_id    
								INNER JOIN journal_entry as je on je.journal_entry_id = jeli.journal_entry_id    
							WHERE balance_sheet_section_id = 65    
								AND YEAR(je.entry_date) <= varCalendarYear
								AND (je.debit_credit_balanced) = 1
								AND (je.cancelled) = 0
							GROUP BY balance_sheet_section_id);
                            
	SET @varLTLCClean = (SELECT CASE WHEN @varLTLC IS NULL or @varLTLC = ' ' THEN 0 ELSE @varLTLC END);
                            
	SET @varLTL = @varLTLCClean - @varLTLDClean;
    
	SET @varDLD = (SELECT SUM(jeli.debit)
							FROM journal_entry_line_item as jeli
								INNER JOIN account as acc on acc.account_id = jeli.account_id    
								INNER JOIN journal_entry as je on je.journal_entry_id = jeli.journal_entry_id    
							WHERE balance_sheet_section_id = 66    
								AND YEAR(je.entry_date) <= varCalendarYear
								AND (je.debit_credit_balanced) = 1
								AND (je.cancelled) = 0
							GROUP BY balance_sheet_section_id);
	
    SET @varDLDClean = (SELECT CASE WHEN @varDLD IS NULL or @varDLD = ' ' THEN 0 ELSE @varDLD END);
    
    SET @varDLC = (SELECT SUM(jeli.credit)
							FROM journal_entry_line_item as jeli
								INNER JOIN account as acc on acc.account_id = jeli.account_id    
								INNER JOIN journal_entry as je on je.journal_entry_id = jeli.journal_entry_id    
							WHERE balance_sheet_section_id = 66    
								AND YEAR(je.entry_date) <= varCalendarYear
								AND (je.debit_credit_balanced) = 1
								AND (je.cancelled) = 0
							GROUP BY balance_sheet_section_id);
                            
	SET @varDLCClean = (SELECT CASE WHEN @varDLC IS NULL or @varDLC = ' ' THEN 0 ELSE @varDLC END);
                            
	SET @varDL = @varDLCClean - @varDLDClean;
    
    SET @varTotalLiabilities = @varCL + @varLTL + @varDL;

	SET @varEqD = (SELECT SUM(jeli.debit)
							FROM journal_entry_line_item as jeli
								INNER JOIN account as acc on acc.account_id = jeli.account_id    
								INNER JOIN journal_entry as je on je.journal_entry_id = jeli.journal_entry_id    
							WHERE balance_sheet_section_id = 67    
								AND YEAR(je.entry_date) <= varCalendarYear
								AND (je.debit_credit_balanced) = 1
								AND (je.cancelled) = 0
							GROUP BY balance_sheet_section_id);
	
    SET @varEqDClean = (SELECT CASE WHEN @varEqD IS NULL or @varEqD = ' ' THEN 0 ELSE @varEqD END);
    
    SET @varEqC = (SELECT SUM(jeli.credit)
							FROM journal_entry_line_item as jeli
								INNER JOIN account as acc on acc.account_id = jeli.account_id    
								INNER JOIN journal_entry as je on je.journal_entry_id = jeli.journal_entry_id    
							WHERE balance_sheet_section_id = 67    
								AND YEAR(je.entry_date) <= varCalendarYear
								AND (je.debit_credit_balanced) = 1
								AND (je.cancelled) = 0
							GROUP BY balance_sheet_section_id);
                            
	SET @varEqCClean = (SELECT CASE WHEN @varEqC IS NULL or @varEqC = ' ' THEN 0 ELSE @varEqC END);
                            
	SET @varEq = @varEqCClean - @varEqDClean;

	SET @varTotalLiabilitiesAndEquity = @varTotalLiabilities + @varEq;
					
	SELECT varCalendarYear as Year, 'BALANCE SHEET' AS Item, '$' AS Balance
		FROM journal_entry 		AS je
		WHERE YEAR(je.entry_date) = varCalendarYear
        
	UNION
        
	SELECT ' ', 'Current Assets', FORMAT(@varCA,2)
    
	UNION

	SELECT ' ', 'Fixed Assets', FORMAT(@varFA,2)
	
    UNION
	
	SELECT ' ', 'Deferred Assets', FORMAT(@varDA,2)

	UNION
    
	SELECT ' ', 'Total Assets', FORMAT(@varTotalAssets,2)
    
    UNION

	SELECT ' ', 'Current Liabilities', FORMAT(@varCL,2)

	UNION

	SELECT ' ', 'Long-Term Liabilities',FORMAT(@varLTL,2)
    
    UNION
    
	SELECT ' ', 'Deferred Liabilities',FORMAT(@varDL,2)
    
    UNION
    
	SELECT ' ', 'Total Liabilities', FORMAT(@varTotalLiabilities,2)

	UNION
    
	SELECT ' ', 'Equity',FORMAT(@varEq, 2)

	UNION
    
	SELECT ' ', 'Total Liabilities & Equity', FORMAT(@varTotalLiabilitiesAndEquity,2);

    END $$

DELIMITER ;	

####################################################################################################################################
# NUMBER PULLING - Here is where you can change the year (update call to match procedure)
####################################################################################################################################

# For Profit-Loss Statement
CALL team9_profit_loss(2018);

# For Balance Sheet
CALL team9_balance_sheet(2018);