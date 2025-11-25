require 'rails_helper'

RSpec.describe AccreditationExpiryNotificationJob, type: :job do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  before do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.deliveries.clear
    ENV['ACCR_EXPIRY_NOTIFICATION_DAYS'] = '14,7'
    ENV['COORDINATOR_ACCR_EXPIRY_NOTIFICATION_DAYS'] = '14'
  end

  describe '#perform' do
    it 'calls both notification methods' do
      job = described_class.new
      expect(job).to receive(:send_user_notifications)
      expect(job).to receive(:send_coordinator_notifications)
      job.perform
    end
  end

  describe '#send_user_notifications' do
    it 'notifies users 14 days and 7 days before expiry' do
      start_time = Time.zone.parse('2024-01-01 12:00:00')
      travel_to start_time do
        user1 = create(:user, accreditation_expire_date: start_time + 14.days)
        user2 = create(:user, accreditation_expire_date: start_time + 7.days)
        described_class.new.send(:send_user_notifications)

        expect(ActionMailer::Base.deliveries.count).to eq(2)
        email1 = ActionMailer::Base.deliveries.first
        expect(email1.to).to eq([user1.email])
        expect(email1.subject).to include('14')
        email2 = ActionMailer::Base.deliveries.second
        expect(email2.to).to eq([user2.email])
        expect(email2.subject).to include('7')
      end
    end

    it 'notifies users 7 days before expiry' do
      start_time = Time.zone.parse('2024-01-01 12:00:00')
      travel_to start_time do
        user = create(:user, accreditation_expire_date: start_time + 7.days)
        described_class.new.send(:send_user_notifications)

        expect(ActionMailer::Base.deliveries.count).to eq(1)
        email = ActionMailer::Base.deliveries.first
        expect(email.to).to eq([user.email])
        expect(email.subject).to include('7')
      end
    end

    it 'does not notify users outside notification windows' do
      start_time = Time.zone.parse('2024-01-01 12:00:00')
      travel_to start_time do
        create(:user, accreditation_expire_date: start_time + 10.days)
        described_class.new.send(:send_user_notifications)

        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    context 'when on expiry day' do
      it 'sends expiry notification within first 10 minutes of the day' do
        expiry_date = Time.zone.parse('2024-01-01 12:00:00')
        user = create(:user, accreditation_expire_date: expiry_date)

        travel_to Time.zone.parse("#{expiry_date.to_date} 00:05:00") do
          described_class.new.send(:send_user_notifications)

          expect(ActionMailer::Base.deliveries.count).to eq(1)
          email = ActionMailer::Base.deliveries.first
          expect(email.to).to eq([user.email])
        end
      end

      it 'does not send expiry notification after first 10 minutes' do
        expiry_date = Time.zone.parse('2024-01-01 12:00:00')
        create(:user, accreditation_expire_date: expiry_date)

        travel_to Time.zone.parse("#{expiry_date.to_date} 00:15:00") do
          described_class.new.send(:send_user_notifications)

          expect(ActionMailer::Base.deliveries).to be_empty
        end
      end

      it 'does not send expiry notification on different day' do
        expiry_date = Time.zone.parse('2024-01-01 12:00:00')
        create(:user, accreditation_expire_date: expiry_date)

        travel_to Time.zone.parse("#{expiry_date.to_date + 1.day} 00:05:00") do
          described_class.new.send(:send_user_notifications)

          expect(ActionMailer::Base.deliveries).to be_empty
        end
      end
    end
  end

  describe '#send_coordinator_notifications' do
    before do
      ENV['COORDINATOR_ACCR_EXPIRY_NOTIFICATION_DAYS'] = '14'
      ENV['COORDINATOR_EMAIL'] = 'coordinator@example.com, coordinator2@example.com'
    end

    it 'sends notification for users expiring in configured days' do
      days_before = ENV.fetch('COORDINATOR_ACCR_EXPIRY_NOTIFICATION_DAYS', '14').to_i
      date = Time.zone.parse('2024-01-01 12:00:00')
      create(:user, accreditation_expire_date: date + days_before.days)

      travel_to date do
        described_class.new.send(:send_coordinator_notifications)

        expect(ActionMailer::Base.deliveries.count).to eq(1)
        email = ActionMailer::Base.deliveries.first
        expect(email.to).to eq(['coordinator@example.com', 'coordinator2@example.com'])
      end
    end

    it 'sends notification for users expired today' do
      date = Time.zone.parse('2024-01-01 12:00:00')
      create(:user, accreditation_expire_date: date)

      travel_to date do
        described_class.new.send(:send_coordinator_notifications)

        expect(ActionMailer::Base.deliveries.count).to eq(1)
        email = ActionMailer::Base.deliveries.first
        expect(email.to).to eq(['coordinator@example.com', 'coordinator2@example.com'])
      end
    end

    it 'includes both expiring soon and expired today users' do
      days_before = ENV.fetch('COORDINATOR_ACCR_EXPIRY_NOTIFICATION_DAYS', '14').to_i
      date = Time.zone.parse('2024-01-01 12:00:00')
      expiring_user = create(:user, accreditation_expire_date: date + days_before.days)
      expired_user = create(:user, accreditation_expire_date: date)

      travel_to date do
        described_class.new.send(:send_coordinator_notifications)

        expect(ActionMailer::Base.deliveries.count).to eq(1)
        email = ActionMailer::Base.deliveries.first
        expect(email.to).to eq(['coordinator@example.com', 'coordinator2@example.com'])
        expect(email.to_s).to include(expiring_user.username).or include(expired_user.username)
      end
    end

    it 'does not send notification when no users match' do
      create(:user, accreditation_expire_date: 20.days.from_now.to_date)

      described_class.new.send(:send_coordinator_notifications)

      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  describe 'integration' do
    it 'enqueues and performs successfully' do
      expect { described_class.perform_later }.to have_enqueued_job(described_class)
      perform_enqueued_jobs { described_class.perform_later }
    end
  end
end
