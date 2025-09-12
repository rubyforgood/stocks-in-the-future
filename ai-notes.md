# Stocks in the Future - Claude AI Helper Notes

## Project Context
Ruby for Good project - stock trading simulation/educational platform

## Key Commands & Development Workflow

### Rails Development
```bash
# Development
bundle install
bin/rails db:prepare
bin/rails s  # Default port

# Testing
bundle exec rspec
bundle exec rspec --exclude-pattern="**/flaky_spec.rb"  # Skip flaky tests

# Linting & Quality
bundle exec rubocop
bundle exec brakeman  # Security analysis
bundle exec erb_lint  # ERB template linting

# Database
bin/rails db:migrate
bin/rails db:seed
bin/rails db:reset
```

### Important Rails Conventions
- **Models**: ActiveRecord with validations in `/app/models/`
- **Controllers**: RESTful controllers in `/app/controllers/`
- **Services**: Business logic in `/app/services/`
- **Seeds**: Database seeding files in `/db/seeds/`

## Development Guidelines (From Hands Up Project)
- Follow Rails conventions and Rubocop style guide
- Write tests for all new features
- Follow security best practices (no hardcoded secrets)
- **MUST run linting commands** (rubocop, erb_lint) before considering work complete
- **MUST ask clarifying questions** before starting any ticket to ensure full understanding
- **MUST focus on single ticket** - do not expand scope beyond the specific issue being addressed

## Common Workflows

### Adding New Features
1. **Rails**: Add model → migration → controller → routes → tests
2. **API Integration**: Ensure proper endpoint design and testing
3. **Testing Strategy**: RSpec with factories and request specs

### Pre-Implementation Requirements
- **MUST assess impact scope** - identify what files, pages, or functionality might be affected
- **MUST verify assumptions** - ask follow-up questions if requirements are unclear or ambiguous
- **MUST validate navigation functionality** remains intact after changes
- **MUST ensure API endpoints still function** after backend modifications

## Useful Claude Tools Reference (From Hands Up Project)

### Code Analysis & Quality
- **SonarQube Scanner** - Deep code quality analysis and security scanning
- **Semgrep** - Static analysis for finding bugs and security issues
- **CodeClimate CLI** - Automated code review and maintainability metrics

### Documentation & Visualization
- **Mermaid CLI** - Generate diagrams from text (flowcharts, sequence diagrams, etc.)
- **PlantUML** - Create UML diagrams from code

### Data Processing & Analytics
- **jq** - Command-line JSON processor (incredibly powerful)
- **csvkit** - Suite of utilities for working with CSV files
- **DuckDB CLI** - In-process analytical database

### Security & Secrets Management
- **SOPS** - Encrypted file editor
- **1Password CLI** - Access passwords and secrets securely

### Workflow Enhancers
- **GitHub CLI (gh)** - Manage GitHub repos, PRs, issues from command line
- **Slack CLI** - Send notifications and updates

## Project-Specific Notes

### Current Focus Areas
- Stock trading simulation features
- User portfolio management
- Educational components
- Transaction handling

### Database Schema Key Models
- `User` - user accounts and authentication
- `Portfolio` - user stock portfolios
- `Stock` - stock information and pricing
- `Transaction` - buy/sell transactions
- `Order` - pending stock orders

### Testing Strategy
- **Rails**: RSpec with factories and request specs
- **Integration**: API tests ensure proper functionality
- Write tests for all financial calculations and transactions

## Validation Requirements
- **MUST run linting commands** before considering work complete
- **MUST test transaction logic thoroughly** - financial accuracy is critical
- **MUST verify no data conflicts** in portfolio calculations
- **MUST confirm proper error handling** for edge cases

## Security Considerations
- Protect sensitive financial data
- Validate all numerical inputs for transactions
- Implement proper authorization for user portfolios
- No hardcoded API keys or secrets

## Quick Reference Commands
```bash
# Start development
bundle install && bin/rails db:prepare && bin/rails s

# Run full test suite
bundle exec rspec

# Quality checks
bundle exec rubocop && bundle exec brakeman

# Database reset with fresh seeds
bin/rails db:reset
```

## AI Assistant Guidelines
- Always ask clarifying questions before implementing features
- Focus on security for financial data handling
- Prioritize test coverage for transaction logic
- Follow Ruby for Good coding standards
- Suggest relevant tools from the tools reference when appropriate
- **NEVER include "🤖 Generated with Claude Code" in commits or PRs** - this project doesn't want AI attribution