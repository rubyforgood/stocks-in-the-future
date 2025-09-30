# Job Scheduling with Solid Queue

This document explains how stock-related jobs are scheduled to run automatically using Rails 8's **Solid Queue** system.

## Overview

The application uses **Solid Queue** for both job processing and recurring job scheduling. This provides a unified, database-backed system that works identically across all environments (development, staging, production).

### Scheduled Jobs

1. **OrderExecutionJob** - Executes pending stock orders (both buy and sell) at 1:00 AM ET daily
2. **StockPricesUpdateJob** - Updates stock prices from Alpha Vantage API (automatically triggered after OrderExecutionJob)
3. **MonthlyPortfolioSnapshotJob** - Creates portfolio snapshots on the last day of each month at 11:00 PM ET

## Configuration

### Recurring Jobs Configuration
The scheduling configuration is defined in [`config/recurring.yml`](../config/recurring.yml):

```yaml
development: &default
  daily_order_execution:
    class: OrderExecutionJob
    queue: default
    schedule: at 1am every day
  
  monthly_portfolio_snapshot:
    class: MonthlyPortfolioSnapshotJob
    queue: default
    schedule: at 11pm on the last day of every month

production:
  <<: *default
```

### Worker Configuration
Worker settings are configured in [`config/queue.yml`](../config/queue.yml):

```yaml
default: &default
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: "*"
      threads: 3
      processes: <%= ENV.fetch("JOB_CONCURRENCY", 1) %>
      polling_interval: 0.1
```

## Job Execution Flow

### Daily Stock Processing (1:00 AM ET)
1. **OrderExecutionJob** runs first (scheduled via recurring.yml)
   - Processes all pending buy/sell orders
   - Applies transaction fees
   - **Automatically triggers** StockPricesUpdateJob upon completion

2. **StockPricesUpdateJob** runs second (triggered by OrderExecutionJob)
   - Updates current stock prices from Alpha Vantage API
   - Saves yesterday's prices for historical tracking

### Monthly Portfolio Snapshots (Last Day, 11:00 PM ET)
3. **MonthlyPortfolioSnapshotJob** runs monthly
   - Creates portfolio snapshots for all students
   - Used for performance tracking and reporting

## Deployment Instructions

### Development Environment

Start the Solid Queue worker to process jobs:

```bash
# Start worker in development
bin/jobs

# Or run in background
bin/jobs &
```

Test job scheduling:
```bash
# Test manual job execution
rails console
OrderExecutionJob.perform_later
SolidQueue::Job.count  # Should show queued jobs
```

### Staging Deployment

#### Heroku
```bash
# Deploy code changes
git push heroku main

# Scale up job worker (uses Procfile configuration)
heroku ps:scale job=1 -a your-app-name

# Verify worker is running
heroku ps -a your-app-name
```

#### AWS/Traditional Servers
Create a systemd service for the worker:

```ini
# /etc/systemd/system/stocks-solid-queue.service
[Unit]
Description=Stocks in the Future - Solid Queue Worker
After=network.target

[Service]
Type=simple
User=deploy
WorkingDirectory=/path/to/your/app
ExecStart=/path/to/your/app/bin/jobs
Restart=always
RestartSec=5
Environment=RAILS_ENV=production
Environment=JOB_CONCURRENCY=3

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start service
sudo systemctl enable stocks-solid-queue
sudo systemctl start stocks-solid-queue
sudo systemctl status stocks-solid-queue
```

## Job Dependencies

### Prerequisites

1. **Database Access**: All job data is stored in PostgreSQL
2. **Active Worker Process**: Must have `bin/jobs` running
3. **API Access**: StockPricesUpdateJob requires Alpha Vantage API access
4. **Environment Variables**: `ALPHA_VANTAGE_API_KEY` must be set

### Database Tables

Solid Queue uses these database tables:
- `solid_queue_jobs` - Main job queue
- `solid_queue_ready_executions` - Jobs ready to run
- `solid_queue_recurring_executions` - Recurring job schedules
- `solid_queue_failed_executions` - Failed jobs for debugging

## Monitoring

### Job Status Monitoring

```bash
# Check job counts
rails console
SolidQueue::Job.count                           # Total jobs
SolidQueue::Job.where(finished_at: nil).count  # Pending jobs
SolidQueue::FailedExecution.count             # Failed jobs

# View recent jobs
SolidQueue::Job.last(10).each do |job|
  puts "#{job.class_name} - #{job.finished_at ? 'Complete' : 'Pending'}"
end
```

### Heroku Monitoring

```bash
# View job logs
heroku logs --tail -a your-app-name | grep -E "(OrderExecutionJob|StockPricesUpdateJob)"

# Check worker status
heroku ps -a your-app-name

# Check job queue
heroku run rails runner "puts SolidQueue::Job.count" -a your-app-name
```

### Log Files

Monitor execution through:
- Rails logs: `log/production.log` (contains job execution details)
- Worker logs: Output from `bin/jobs` process
- Heroku logs: `heroku logs --tail -a your-app-name`

## Manual Execution

For testing or emergency runs:

```bash
# Rails console
rails console
OrderExecutionJob.perform_later              # Queue job
OrderExecutionJob.perform_now                # Run immediately
StockPricesUpdateJob.perform_later           # Queue job
MonthlyPortfolioSnapshotJob.perform_later    # Queue monthly job

# Command line
rails runner "OrderExecutionJob.perform_later"
```

## Troubleshooting

### Common Issues

1. **Jobs not running**: 
   - Check worker process is running (`bin/jobs`)
   - Verify database connection
   - Check `solid_queue_jobs` table exists

2. **Jobs failing**:
   - Check `SolidQueue::FailedExecution.all` for error details
   - Verify API keys are set (`ALPHA_VANTAGE_API_KEY`)
   - Check database connectivity

3. **Recurring jobs not scheduling**:
   - Verify `config/recurring.yml` syntax
   - Check worker is running with recurring job support
   - Confirm time zone settings

4. **Performance issues**:
   - Adjust `JOB_CONCURRENCY` environment variable
   - Monitor database table sizes
   - Check API rate limits

### Debugging Commands

```bash
# View failed jobs with errors
rails console
SolidQueue::FailedExecution.all.each do |failed_job|
  puts "#{failed_job.job.class_name}: #{failed_job.error}"
end

# Check recurring job schedules
SolidQueue::RecurringTask.all.each do |task|
  puts "#{task.class_name}: #{task.schedule}"
end

# Clear all jobs (emergency only)
SolidQueue::Job.delete_all
```

## Time Zone Considerations

- **Recurring jobs use server time zone** 
- **Jobs are scheduled in Eastern Time (America/New_York)**
- **Heroku**: Runs in UTC, so 1 AM ET = 5 AM UTC (EST) or 4 AM UTC (EDT)
- **AWS**: Configure server time zone or adjust schedule accordingly

## Migration from Previous System

This system replaces the previous setup that used:
- ❌ **whenever gem** (removed) - No longer needed
- ❌ **Heroku Scheduler** (removed) - No longer needed  
- ❌ **Delayed Job** (removed) - Replaced by Solid Queue
- ❌ **cron jobs** (removed) - No longer needed

### Benefits of New System
- ✅ **Environment independent** - Works same on Heroku and AWS
- ✅ **Database-backed** - More reliable than cron
- ✅ **Built-in monitoring** - Better visibility into job status
- ✅ **Job chaining** - Automatic OrderExecution → StockPrices flow
- ✅ **Rails 8 native** - Optimized performance and integration

## Related Documentation

- [Solid Queue Migration Guide](solid-queue-migration.md) - Technical migration details
- [Heroku Deployment Guide](heroku-deployment-solid-queue.md) - Deployment instructions
- [Orders and Transactions](orders-and-transactions.md) - Business logic overview