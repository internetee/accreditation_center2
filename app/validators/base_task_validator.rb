# app/validators/base_task_validator.rb
class BaseTaskValidator
  def initialize(attempt:, question:, config:)
    @attempt, @question, @config = attempt, question, config
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
end
