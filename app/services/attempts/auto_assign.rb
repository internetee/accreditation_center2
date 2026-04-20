module Attempts
  # Automatically assigns missing theoretical/practical attempts to a user.
  class AutoAssign
    Failure = Struct.new(:test_type, :error_message, keyword_init: true)

    def initialize(user:)
      @user = user
    end

    def call
      missing_test_types.each_with_object([]) do |test_type, failures|
        assign_for(test_type)
      rescue StandardError => e
        failures << Failure.new(test_type: test_type, error_message: e.message)
      end
    end

    private

    attr_reader :user

    def missing_test_types
      Test.test_types.keys.reject { |type| active_attempt_for?(type) }
    end

    def active_attempt_for?(type)
      user.test_attempts
          .not_completed
          .joins(:test)
          .where(tests: { test_type: Test.test_types[type] })
          .reject(&:time_expired?)
          .any?
    end

    def assign_for(test_type)
      test = next_assignable_test_for(test_type)
      raise StandardError, "No #{test_type} tests available" unless test

      Attempts::Assign.call!(user: user, test: test)
    end

    def next_assignable_test_for(test_type)
      assigned_ids = user.test_attempts.not_completed.pluck(:test_id)
      scope = Test.active.auto_assignable.where(test_type: test_type)
      scope = scope.where.not(id: assigned_ids) if assigned_ids.present?
      scope.first || Test.active.auto_assignable.where(test_type: test_type).first
    end
  end
end
