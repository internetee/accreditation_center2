namespace :test_attempts do
  desc 'Purge detailed results older than 30 days (keeps completion time and pass/fail)'
  task purge_old_details: :environment do
    TestAttempt.purge_old_details!
    puts 'Purged detailed results older than 30 days'
  end
end


