# app/validators/base_task_validator.rb
class BaseTaskValidator
  def initialize(attempt:, config:, inputs:)
    @attempt = attempt
    @config = config
    @inputs = inputs
    @service = api_service_adapter(@attempt.user)
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

  def api_service_adapter(_user)
    nil
  end
end
