# frozen_string_literal: true

namespace :test_attempts do
  desc 'Fix task 5 (nameserver management) body and validator for practical-test-v2 so ns1_1/ns2_1 are shown'
  task fix_task5_nameservers: :environment do
    t = Test.find_by(slug: 'practical-test-v2')
    task = t&.practical_tasks&.find_by(display_order: 5)
    abort 'Task 5 not found' unless task
    task.update!(
      body_en: "Add/update nameservers of the domains created in the previous step.\nFor {{domain1}}: \n- Hostname {{ns1_1}}\nFor {{domain2}}:\n- Hostname {{ns2_1}}",
      body_et: "Lisa/uuda nimeserverid domeenidele, mis on loodud eelmises sammos.\n{{domain1}}:\n- Hostname {{ns1_1}}\n{{domain2}}:\n- Hostname {{ns2_1}}",
      validator: {
        klass: 'UpdateNameserversValidator',
        config: { nameservers: { '{{domain1}}' => '{{ns1_1}}', '{{domain2}}' => '{{ns2_1}}' } },
        input_fields: [],
        allocators: [{ name: 'nameservers', config: { count: 1, use_faker: true } }],
        depends_on_task_ids: [2]
      }.to_json
    )
    puts 'Task 5 (nameserver management) updated: body and validator now include ns1_1, ns2_1'
  end

  desc 'Set renewal task (display_order 7) to years: 6 for practical-test-v2'
  task update_renewal_years: :environment do
    t = Test.find_by(slug: 'practical-test-v2')
    task = t&.practical_tasks&.find_by(display_order: 7)
    abort 'Renewal task not found' unless task
    v = task.validator.is_a?(String) ? JSON.parse(task.validator) : task.validator
    v['config'] ||= {}
    v['config']['years'] = 6
    task.update_column(:validator, v.to_json)
    puts 'Renewal task updated: years = 6'
  end

  desc 'Purge detailed results older than 30 days (keeps completion time and pass/fail)'
  task purge_old_details: :environment do
    TestAttempt.purge_old_details!
    puts 'Purged detailed results older than 30 days'
  end

  desc 'Run renewal task validator for an attempt (local check without UI). Usage: rails test_attempts:validate_renewal[ACCESS_CODE] or rails test_attempts:validate_renewal[ACCESS_CODE,password]'
  task :validate_renewal, [:access_code, :password] => :environment do |_t, args|
    access_code = args[:access_code] || ENV['ACCESS_CODE']
    password = args[:password] || ENV['VALIDATE_PASSWORD'] || 'password'
    abort 'Give attempt access_code: rails test_attempts:validate_renewal[ACCESS_CODE]' if access_code.blank?

    attempt = TestAttempt.find_by(access_code: access_code)
    abort "Attempt with access_code #{access_code} not found" unless attempt

    task = attempt.test.practical_tasks.active.ordered.find { |t| t.klass_name == 'RenewDomainValidator' }
    abort 'Renewal task (RenewDomainValidator) not found for this test' unless task

    token = ApiTokenService.new(username: attempt.user.username, password: password).generate
    validator = RenewDomainValidator.new(attempt: attempt, config: task.conf, inputs: {}, token: token)
    result = validator.call

    if result[:passed]
      puts 'OK: Renewal validation passed.'
      puts "  domain: #{result[:evidence][:domain]}"
    else
      puts 'FAIL: Renewal validation failed.'
      puts "  errors: #{result[:errors]&.join(', ')}"
      puts "  api_audit: #{result[:api_audit]}" if result[:api_audit].present?
    end
    exit(result[:passed] ? 0 : 1)
  end
end
