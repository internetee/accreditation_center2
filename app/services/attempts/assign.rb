# app/services/attempts/assign.rb
module Attempts
  # Creates a test attempt and provisions practical tasks when applicable.
  class Assign
    def self.call!(user:, test:)
      ApplicationRecord.transaction(requires_new: true) do
        attempt = TestAttempt.create!(
          user: user,
          test: test,
          access_code: SecureRandom.hex(8),
          started_at: nil
        )

        # Run all allocators declared on this test’s practical tasks.
        Provisioner.provision!(attempt) if test.practical? # raises on failure

        attempt # committed only if provision! didn’t raise
      end
    end
  end
end
