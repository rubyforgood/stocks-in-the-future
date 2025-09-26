# Claude Code Configuration

This file contains configuration and notes for Claude Code usage in the Stocks in the Future project.

## Important Setup Notes
⚠️ **Claude File Location**: This CLAUDE.md file cannot be committed to the project repository. It should remain in the local working directory only.

⚠️ **Directory Navigation**: Claude Code sessions typically start in the parent directory (`/Users/erinclaudio/Desktop/RFG/`). Always navigate into the project folder (`stocks-in-the-future/`) before running project commands or using tools like `gh` CLI.

## User Workflow Preferences
**Work Style**: Prefer working in small, incremental steps with confirmation at each stage rather than large changes all at once.

**Multi-Terminal Setup**: Uses three command line windows:
1. **Mother Terminal**: Non-coding instance for general tasks, navigation, and oversight
2. **Worker Terminal**: Primary coding workspace where development work is performed
3. **Server Terminal**: Dedicated terminal for running the Rails server (`bin/rails server`)

## Commands
- Setup (Mac/Linux): `bin/setup`
- Dev server: `bin/dev` (includes Rails server)
- Test: `bundle exec rails test` or `bin/rails test`
- Test all: `bin/dev rails test:all`
- Test specific: `bundle exec rails test test/models/portfolio_stock_test.rb`
- Lint: `bin/lint` (RuboCop)
- Lint autofix: `bundle exec rubocop -A`
- Console: `bin/rails console`
- Server: `bin/rails server`
- DB setup: `bin/rails db:setup`
- DB migrate: `bin/rails db:migrate`
- Seed data: `bin/rails db:seed`
- Coverage: `bin/coverage` (generates HTML report at coverage/index.html)

### Docker Commands
- Build/start: `docker compose up`
- Run commands: `bin/dc rails [command]` or `docker compose run stocks rails [command]`

## GitHub CLI Commands
- List PRs: `gh pr list`
- View PR: `gh pr view [number]`
- View PR diff: `gh pr diff [number]`
- Review PR: `gh pr review [number]`

## Project Notes
- Ruby on Rails application for stock market simulation
- Uses Tailwind CSS for styling
- GitHub CLI available via `gh` command
- Portfolio calculations in `app/models/portfolio_stock.rb`
- Main portfolio view: `app/views/portfolios/show.html.erb`
- Price data stored in cents (price_cents) in database
- **Important**: Purchase prices may be stored inconsistently (dollars vs cents) - see PortfolioStock model normalization logic

## Key Models
- `PortfolioStock`: Handles change_amount and total_return_amount calculations
  - `change_amount`: (current_price - purchase_price) × shares
  - `total_return_amount`: current_price × shares
  - Note: Contains price normalization logic for cents/dollars mismatch
- `Portfolio`: User's stock holdings and cash balance
- `Stock`: Individual stock data with current prices (stored as price_cents)

## Development Setup
- Ruby 3.4.4 (use ruby version manager: rvm, rbenv, or asdf)
- Ruby on Rails project
- PostgreSQL database (or use Docker)
- npm and yarn for frontend dependencies
- Uses FactoryBot for test fixtures
- RuboCop for code style enforcement
- GitHub Actions for CI/CD
- Access app at: `localhost:3000`

### Seed Users (after `bin/rails db:setup`)
| Role    | Username | Password |
|---------|----------|----------|
| Teacher | Teacher  | password |
| Student | Student  | password |
| Admin   | Admin    | password |

## Testing Notes
- Test files in `test/` directory
- Use `create(:portfolio_stock)` for test data
- Coverage reports generated to `coverage/` directory
- Portfolio stock calculations have comprehensive test coverage including edge cases

## Common Issues & Solutions
### Portfolio Table Calculations
- **Problem**: Change column showing $0.00 due to `current_price - current_price = 0`
- **Solution**: Use `PortfolioStock#change_amount` method which calculates `(current_price - purchase_price) × shares`
- **Testing**: Update stock price via `bin/rails runner "Stock.find_by(ticker: 'BAC').update(price_cents: 5500)"`

### Data Inconsistency
- Purchase prices may be stored in dollars while current prices are in cents
- PortfolioStock model includes normalization logic to handle this mismatch
- Consider database migration to ensure consistent storage format

## Common Local Environment Issues

### Tailwind CSS Not Compiling (@apply directives not working)
**Symptoms:**
- Massive SVG logos taking up entire screen
- Custom CSS classes like `.navbar-logo` not applying proper styles
- Console debugging shows `height: 0px` and excessive width values

**Root Cause:**
Tailwind CSS `@apply` directives in custom CSS files (like `navbar.css`) aren't being compiled properly in development.

**Solution:**
```bash
bin/rails assets:precompile
rm -f public/assets/.manifest.json  # if still broken
```

**Prevention:**
Use `bin/dev` instead of `bin/rails server` to ensure CSS compilation runs alongside the server.

## Repository Information
- GitHub: rubyforgood/stocks-in-the-future
- Remote: git@github.com:rubyforgood/stocks-in-the-future.git
- Use `gh` CLI for PR management and reviews

## Git Workflow
1. Branch from main: `git checkout -b feature-description-123`
2. Make changes and commit
3. Run linting: `bin/lint` (autofix: `bundle exec rubocop -A`)
4. Run tests: `bin/rails test`
5. Push: `git push --set-upstream origin branch-name`
6. Create PR against main branch with "Fixes #issue-number"