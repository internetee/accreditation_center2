require 'rails_helper'

RSpec.describe RegistrarAccreditationNotificationsService do
  include ActiveJob::TestHelper

  describe "#notify_test_completion" do
    let(:service) { described_class.new }
    let(:user) { create(:user) }
    let(:registrar) { user.registrar }

    it 'sends practical-pass notice once while registrar is not accredited' do
      practical_test = create(:test, :practical, passing_score_percentage: 100)
      test_attempt = create(:test_attempt, :passed, user: user, test: practical_test)

      allow(RegistrarAccreditationEligibility).to receive(:accredited?).with(registrar).and_return(false)

      expect {
        service.notify_test_completion(test_attempt)
      }.to have_enqueued_mail(AccreditationMailer, :practical_passed_not_accredited)

      expect {
        service.notify_test_completion(test_attempt)
      }.not_to have_enqueued_mail(AccreditationMailer, :practical_passed_not_accredited)
    end

    it 'suppresses test-pass notices when registrar became accredited in same flow' do
      theoretical_test = create(:test, :theoretical)
      test_category = create(:test_category)
      create(:test_categories_test, test: theoretical_test, test_category: test_category)
      question = create(:question, test_category: test_category)
      create(:answer, question: question, correct: true)
      test_attempt = create(:test_attempt, :passed, user: user, test: theoretical_test)

      allow(RegistrarAccreditationEligibility).to receive(:accredited?).with(registrar).and_return(true)

      expect {
        service.notify_test_completion(test_attempt)
      }.not_to have_enqueued_mail(AccreditationMailer, :theoretical_passed_not_accredited)
    end
  end

  describe "#notify_accreditation_sync" do
    let(:service) { described_class.new }
    let(:registrar) { create(:registrar, accreditation_date: Time.zone.parse("2026-04-10 10:00:00"), accreditation_expire_date: Time.zone.parse("2028-04-10 10:00:00")) }

    it 'sends first-accreditation confirmation once' do
      expect {
        service.notify_accreditation_sync(
          registrar: registrar,
          previous_accreditation_date: nil,
          previous_accreditation_expire_date: nil
        )
      }.to have_enqueued_mail(AccreditationMailer, :accreditation_granted_or_reaccredited)

      expect {
        service.notify_accreditation_sync(
          registrar: registrar,
          previous_accreditation_date: nil,
          previous_accreditation_expire_date: nil
        )
      }.not_to have_enqueued_mail(AccreditationMailer, :admin_accreditation_window_notice)

      expect {
        service.notify_accreditation_sync(
          registrar: registrar,
          previous_accreditation_date: nil,
          previous_accreditation_expire_date: nil
        )
      }.not_to have_enqueued_mail(AccreditationMailer, :accreditation_granted_or_reaccredited)
    end

    it 'sends reaccreditation confirmation and admin notice in window, once per cycle' do
      previous_expiry = Time.zone.parse("2026-04-20 00:00:00")
      registrar.update!(accreditation_date: Time.zone.parse("2026-04-05 12:00:00"))

      expect {
        service.notify_accreditation_sync(
          registrar: registrar,
          previous_accreditation_date: Time.zone.parse("2024-04-20 00:00:00"),
          previous_accreditation_expire_date: previous_expiry
        )
      }.to have_enqueued_mail(AccreditationMailer, :accreditation_granted_or_reaccredited)
        .and have_enqueued_mail(AccreditationMailer, :admin_accreditation_window_notice)

      expect {
        service.notify_accreditation_sync(
          registrar: registrar,
          previous_accreditation_date: Time.zone.parse("2024-04-20 00:00:00"),
          previous_accreditation_expire_date: previous_expiry
        )
      }.not_to have_enqueued_mail(AccreditationMailer, :admin_accreditation_window_notice)
    end

    it 'does not send reaccreditation notifications outside window' do
      previous_expiry = Time.zone.parse("2026-04-20 00:00:00")
      registrar.update!(accreditation_date: Time.zone.parse("2026-03-01 12:00:00"))

      expect {
        service.notify_accreditation_sync(
          registrar: registrar,
          previous_accreditation_date: Time.zone.parse("2024-04-20 00:00:00"),
          previous_accreditation_expire_date: previous_expiry
        )
      }.not_to have_enqueued_mail(AccreditationMailer, :admin_accreditation_window_notice)

      expect {
        service.notify_accreditation_sync(
          registrar: registrar,
          previous_accreditation_date: Time.zone.parse("2024-04-20 00:00:00"),
          previous_accreditation_expire_date: previous_expiry
        )
      }.not_to have_enqueued_mail(AccreditationMailer, :accreditation_granted_or_reaccredited)
    end
  end

  describe "#notify_daily_expiry_checks" do
    let(:service) { described_class.new }
    let(:reference_date) { Date.new(2026, 4, 27) }

    it 'sends 30-day reminder once per registrar per expiry cycle' do
      create(
        :registrar,
        accreditation_expire_date: Time.zone.parse("2026-05-27 10:00:00")
      )

      expect {
        service.notify_daily_expiry_checks(reference_date: reference_date)
      }.to have_enqueued_mail(AccreditationMailer, :expiry_30_days)

      expect {
        service.notify_daily_expiry_checks(reference_date: reference_date)
      }.not_to have_enqueued_mail(AccreditationMailer, :expiry_30_days)
    end

    it 'sends expiry/passed notice on or after expiry once per cycle' do
      create(
        :registrar,
        accreditation_expire_date: Time.zone.parse("2026-04-26 10:00:00")
      )

      expect {
        service.notify_daily_expiry_checks(reference_date: reference_date)
      }.to have_enqueued_mail(AccreditationMailer, :expiry_or_passed)

      expect {
        service.notify_daily_expiry_checks(reference_date: reference_date + 1.day)
      }.not_to have_enqueued_mail(AccreditationMailer, :expiry_or_passed)
    end

    it 'does not send reminders for non-matching expiry dates' do
      create(
        :registrar,
        accreditation_expire_date: Time.zone.parse("2026-06-10 10:00:00")
      )

      expect {
        service.notify_daily_expiry_checks(reference_date: reference_date)
      }.not_to have_enqueued_mail(AccreditationMailer, :expiry_30_days)

      expect {
        service.notify_daily_expiry_checks(reference_date: reference_date)
      }.not_to have_enqueued_mail(AccreditationMailer, :expiry_or_passed)
    end
  end
end
