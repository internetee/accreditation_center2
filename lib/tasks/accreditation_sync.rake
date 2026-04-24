# frozen_string_literal: true

# This task is used to sync accreditation results to REPP API
# Run with: bin/rails accreditation:sync_to_repp
namespace :accreditation do
  desc 'Sync accreditation results to REPP API'
  task sync_to_repp: :environment do
    puts 'Syncing accreditation results to REPP API...'

    service = AccreditationResultsService.new
    synced_count = service.sync_all_accredited_registrars

    puts "Synced #{synced_count} registrars to REPP API"
  rescue StandardError => e
    warn "Accreditation sync failed: #{e.message}"
    raise
  end

  desc 'Sync accreditation for one registrar_name'
  task :sync_registrar, [:registrar_name] => :environment do |_t, args|
    registrar_name = args[:registrar_name].to_s.strip
    if registrar_name.blank?
      warn 'Error: Please provide registrar_name'
      warn 'Usage: bin/rails "accreditation:sync_registrar[Registrar Name]"'
      exit 1
    end

    service = AccreditationResultsService.new
    registrar = Registrar.find_by(name: registrar_name)
    if registrar.blank?
      warn "Registrar not found: '#{registrar_name}'"
      exit 1
    end

    result = service.sync_registrar_accreditation(registrar)

    if result[:success]
      puts "Successfully synced accreditation for registrar '#{registrar_name}'"
    else
      warn "Failed to sync accreditation for registrar '#{registrar_name}': #{result[:message]}"
      exit 1
    end
  rescue StandardError => e
    warn "Accreditation sync failed for registrar '#{registrar_name}': #{e.message}"
    raise
  end
end
