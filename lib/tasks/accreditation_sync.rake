# frozen_string_literal: true

namespace :accreditation do
  desc 'Sync accreditation results to REPP API'
  task sync_to_repp: :environment do
    puts 'Syncing accreditation results to REPP API...'

    service = AccreditationResultsService.new
    synced_count = service.sync_all_accredited_users

    puts "Synced #{synced_count} users to REPP API"
  end

  desc 'Sync specific user accreditation'
  task :sync_user, [:username] => :environment do |_t, args|
    username = args[:username]

    if username.blank?
      puts 'Error: Please provide a username'
      exit 1
    end

    user = User.find_by(username: username)

    if user.nil?
      puts "Error: User '#{username}' not found"
      exit 1
    end

    service = AccreditationResultsService.new

    if service.user_accredited?(user)
      result = service.sync_user_accreditation(user)

      if result[:success]
        puts "Successfully synced accreditation for #{username}"
      else
        puts "Failed to sync accreditation: #{result[:message]}"
      end
    else
      puts "User '#{username}' is not accredited"
    end
  end
end
