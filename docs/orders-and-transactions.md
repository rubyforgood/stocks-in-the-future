# Orders and Transactions

This document outlines how orders and transactions function in terms of this application. 
Note that due to the fundamental way in which this system works, these concepts are different than you might typically expect from a stock trading platform.

## [Orders](../app/models/order.rb)
- Students can place buy or sell orders for stocks. These orders are not executed immediately but are pending until they are processed by the [OrderExecutionJob](../app/jobs/order_execution_job.rb) at the end of each day.
  - Currently, this job runs a midnight Eastern Time.
- Students can cancel or update their pending orders at any time before they have been executed.
- At this time, orders can only be placed for whole shares of stock (no fractional shares).
- When placing an order, the price of the stock is a known value. This is because we only update the stock prices once per day, and we execute all pending orders before updating the prices for the next day.

### Transaction Fees
- There is a flat transaction fee of $1.00 per student per day for executing orders, regardless of the number of orders placed.
- Here are some examples: 
  - A student places a buy order for 2 shares of stock A at $10 each. They will be charged $20 for the shares plus a $1 transaction fee, totaling $21.
  - A student places buy orders for 1 share of stock A at $10 and 1 share of stock B at $15 on the same day. They will be charged $10 + $15 + $1 transaction fee, totaling $26.
  - A student places a sell order for 3 shares of stock A at $10 each. They will receive $30 from the sale minus the $1 transaction fee, totaling $29.

### Validations

#### Buy Orders
- When placing a buy order, the system checks if the student has sufficient cash in their portfolio to cover the cost of the shares plus the $1 transaction fee.
  - Note that the system must correctly consider that multiple buy orders placed on the same day will incur only a single $1 transaction fee.
  - The system also considers the total cost of all buy orders placed on that day when validating if the student has enough cash.
  
#### Sell Orders
- When placing a sell order, the system checks if the student has enough shares of the stock they wish to sell in their portfolio.

## [Transactions](../app/models/portfolio_transaction.rb) 
- Transactions are records of cash movements in a student's portfolio.
- Transactions can be of the following types:
  - **Deposit** - represents cash added to the portfolio through earnings from gradebook or manual deposits by teachers/admins
  - **Withdrawal** - represents cash removed from the portfolio by teachers/admins
  - **Credit** - represents cash received from selling stocks
  - **Debit** - represents cash spent on buying stocks
  - **Fee** - represents the $1 transaction fee charged for executing orders
- Transactions can be associated with an order if they are the result of executing a buy or sell order. However not every transaction is linked to an order (e.g., deposits, withdrawals, and fees).
- Transactions are immutable records and should not be edited or deleted after they are created
- Note that the transactions table is designed to be a ledger, thus if you want to calculate the current cash balance of a portfolio, you should sum up all the transactions. This is why the portfolios table does not have a cash balance column.