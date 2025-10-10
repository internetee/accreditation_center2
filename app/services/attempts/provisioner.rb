# app/services/attempts/provisioner.rb
module Attempts
  # Provisions practical tasks for a given test attempt by invoking allocators.
  class Provisioner
    def self.provision!(test_attempt)
      test = test_attempt.test
      tasks = test.practical_tasks.active

      tasks.each do |task|
        Array(task.vconf['allocators']).each do |decl|
          Allocators::Registry.run!(
            name: decl['name'],
            config: decl['config'] || {},
            attempt: test_attempt
          )
        end
      end
    end
  end
end
