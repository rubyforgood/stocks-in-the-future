# Schema

- schools
  - id
  - name

- years
  - id
  - year

- school_years
  - id
  - school_id
  - year_id

- classrooms
  - id
  - school_year_id
  - name
  - grade
  - teacher_id

Inheritance?
- users
  - id
  - type
    - student
    - teacher
    - admin
  - username
  - password
  - email

- user_invites
  - id
  - invite_code
  - type
    - student
    - teacher
    - admin
  - date

- stocks
  - id
  - name
  - ticker
  - ...company details

- stock_prices
  - id
  - stock_id
  - date
  - open
  - high
  - low
  - close
  - volume
  - adj_close

- stock_dividends
  - id
  - stock_id
  - date
  - dividend

!!!! Use Transactions
- portfolio
  - id
  - user_id
  - cash_amount

- portfolio_transactions
  - id
  - portfolio_id
  - actor_id
  - date
  - amount
  - type
    - deposit
    - withdrawal

- portfolio_stocks
  - id
  - portfolio_id
  - stock_id
  - shares

- portfolio_stock_transactions
  - id
  - portfolio_stock_id
  - stock_id
  - date
  - shares
  - price
  - type
    - buy
    - sell
    - dividend
  - ...other details