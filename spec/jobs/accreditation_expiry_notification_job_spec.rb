require 'rails_helper'

RSpec.describe AccreditationExpiryNotificationJob, type: :job do
  include ActiveJob::TestHelper

  it 'enqueues and performs' do
    expect { described_class.perform_later }.to have_enqueued_job(described_class)
    perform_enqueued_jobs { described_class.perform_later }
  end
end
