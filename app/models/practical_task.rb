class PracticalTask < ApplicationRecord
  belongs_to :test
  positioned on: :test, column: :display_order

  scope :ordered, -> { order(:display_order) }
  scope :active, -> { where(active: true) }

  validates :display_order, presence: true, numericality: { greater_than: 0 }

  translates :title, :body

  def vconf
    raw = validator
    raw = JSON.parse(raw) if raw.is_a?(String)
    (raw || {}).with_indifferent_access
  end

  def klass_name
    vconf[:klass]
  end

  def conf
    vconf[:config] || {}
  end

  def input_fields
    Array(vconf[:input_fields])
  end

  def deps
    Array(vconf[:depends_on_task_ids])
  end

  before_validation :auto_deactivate_if_no_validator

  private

  def auto_deactivate_if_no_validator
    raw = validator || {}
    raw = JSON.parse(raw) if raw.is_a?(String)
    conf = raw || {}
    self.active = false if conf.blank? || conf['klass'].blank?
  end
end
