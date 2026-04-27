class Admin::JobsController < Admin::BaseController
  def index
    @registrars = Registrar.order(:name)
  end

  def accreditation_sync
    registrar = Registrar.find_by(id: params[:registrar_id])

    unless registrar
      redirect_to({ action: :index }, alert: t('.invalid_registrar', default: 'Please choose a valid registrar.'))
      return
    end

    AccreditationSyncJob.perform_later(registrar)
    redirect_to({ action: :index }, notice: t('.enqueued', default: 'Accreditation sync job was enqueued.'))
  end

  def expiry_check
    reference_date = parse_reference_date(params[:reference_date])

    unless reference_date
      redirect_to({ action: :index }, alert: t('.invalid_date', default: 'Please enter a valid date.'))
      return
    end

    ExpiryCheckJob.perform_later(reference_date)
    redirect_to({ action: :index }, notice: t('.enqueued', default: 'Expiry check job was enqueued.'))
  end

  private

  def parse_reference_date(raw_date)
    return Time.zone.today if raw_date.blank?

    Date.iso8601(raw_date)
  rescue ArgumentError
    nil
  end
end
