web: bundle exec puma -C config/puma.rb
job: bin/jobs
scheduler: bin/rake solid_queue:start_scheduler
release: bundle exec rails db:migrate