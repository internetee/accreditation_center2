# app/validators/base_task_validator.rb
class BaseTaskValidator
  def initialize(attempt:, config:, inputs:, token: nil)
    @attempt = attempt
    @config = config
    @inputs = inputs
    @token = token
    @service = api_service_adapter
  end

  def call
    # return a Hash with: passed(bool), score(Float 0..1), evidence(Hash), error(String|nil),
    # api_audit(Array), export_vars(Hash)
    raise NotImplementedError
  end

  protected

  def v(key)
    @attempt.vars[key.to_s]
  end

  def api_service_adapter
    raise NotImplementedError
  end

  def parse_time(val)
    return val if val.is_a?(Time) || val.is_a?(ActiveSupport::TimeWithZone)
    return nil if val.nil?

    Time.zone.parse(val.to_s)
  rescue StandardError => e
    Rails.logger.error "Error parsing time: #{e.message}"
    nil
  end

  def compute_window_and_cutoff
    window = (@config['window_minutes'] || 15).to_i
    window = 15 if window <= 0
    cutoff = Time.current - window.minutes

    [window, cutoff]
  end

  def pass(api, evidence = {}, export_vars = {})
    { passed: true, score: 1.0, evidence: evidence, errors: nil, api_audit: api, export_vars: export_vars }
  end

  def failure(api, errs)
    { passed: false, score: 0.0, evidence: {}, errors: errs, api_audit: api, export_vars: {} }
  end

  def with_audit(api, operation)
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    res = yield
    api << { op: operation, ok: !res.nil?, ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1000).round }
    res
  rescue StandardError => e
    api << { op: operation, ok: false, error: e.message }
    nil
  end
end
