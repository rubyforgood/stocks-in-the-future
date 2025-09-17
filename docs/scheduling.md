# Job Scheduling with Whenever Gem

This document explains how the stock-related jobs are scheduled to run automatically using the `whenever` gem.

## Overview

The application uses the `whenever` gem to schedule two jobs that run daily at 1:00 AM Eastern Time:

1. **OrderExecutionJob** - Executes pending stock orders (both buy and sell)
2. **StockPricesUpdateJob** - Updates stock prices from Alpha Vantage API

## Configuration

The scheduling configuration is defined in [`config/schedule.rb`](../config/schedule.rb):

```ruby
every 1.day, at: '1:00 am' do
  runner "OrderExecutionJob.perform_later"
  runner "StockPricesUpdateJob.perform_later"
end
```

## Deployment Instructions

### Development Environment

To test the schedule configuration locally:

```bash
# View the generated cron syntax
bundle exec whenever

# View with specific environment
bundle exec whenever --set environment=development
```

### Production Deployment

#### 1. Install Cron Jobs

After deploying your application, update the server's crontab:

```bash
# Update crontab with production environment
bundle exec whenever --update-crontab --set environment=production

# Or specify a custom identifier
bundle exec whenever --update-crontab stocks-app --set environment=production
```

#### 2. Verify Installation

Check that the cron jobs were installed correctly:

```bash
# List current crontab
crontab -l

# You should see entries like:
# 0 1 * * * /bin/bash -l -c 'cd /path/to/app && bundle exec bin/rails runner -e production '\''StockPricesUpdateJob.perform_later'\'''
```

#### 3. Remove Cron Jobs (if needed)

To remove the scheduled jobs:

```bash
# Remove all whenever jobs
bundle exec whenever --clear-crontab

# Or remove specific identifier
bundle exec whenever --clear-crontab stocks-app
```
## Job Dependencies

### Prerequisites

1. **Delayed Job Workers**: Ensure delayed job workers are running to process the queued jobs:
   ```bash
   bundle exec bin/delayed_job start
   ```

2. **Database Access**: Jobs need database connectivity to update stock records and process orders.

3. **API Access**: StockPricesUpdateJob requires internet access to reach Alpha Vantage API.

### Job Execution Order

The jobs are scheduled to run at the same time (1:00 AM), but they will be queued in order:
1. StockPricesUpdateJob runs first (updates current stock prices)
2. OrderExecutionJob runs second (processes orders with updated prices)

## Monitoring

### Log Files

Monitor job execution through:
- Rails logs: `log/production.log`
- Delayed Job logs: Check delayed job worker output
- System cron logs: `/var/log/cron` (Linux) or Console.app (macOS)

### Manual Execution

For testing or emergency runs:

```bash
# Run jobs manually in Rails console
rails console
OrderExecutionJob.perform_now
StockPricesUpdateJob.perform_now

# Or queue them
OrderExecutionJob.perform_later
StockPricesUpdateJob.perform_later
```

## Troubleshooting

### Common Issues

1. **Jobs not running**: Check crontab installation and delayed job workers
2. **Wrong timezone**: Ensure server timezone matches expected schedule
3. **Permission errors**: Verify cron has proper file permissions
4. **Environment issues**: Confirm Rails environment is set correctly

### Debugging

```bash
# Test schedule generation
bundle exec whenever --set environment=production

# Check cron logs
tail -f /var/log/cron

# Monitor delayed job queue
rails console
Delayed::Job.count
```

## Time Zone Considerations

The schedule uses the server's local time zone. For Eastern Time:
- Ensure server is configured for ET timezone, or
- Adjust schedule time based on server's timezone offset

Example for UTC server running ET schedule:
```ruby
# For UTC server, 1 AM ET = 5 AM UTC (standard time) or 6 AM UTC (daylight time)
every 1.day, at: '5:00 am' do  # Adjust based on DST
  # jobs here
end