class RegistrarController < ApplicationController
  before_action :ensure_regular_user!

  def show
    @registrar = current_user.registrar
    return handle_missing_registrar if @registrar.blank?

    @registrar_users = @registrar.users
                                 .not_admin
                                 .includes(test_attempts: :test)
                                 .order(:name, :email)
    @latest_result_by_user_id = build_latest_result_projection(@registrar_users)
    @colleague_rows = build_colleague_rows(@registrar_users, @latest_result_by_user_id)
    @colleague_rows = filter_colleague_rows(@colleague_rows, params[:q]) if params[:q].present?
    @colleague_rows = sort_colleague_rows(@colleague_rows, params[:sort], params[:direction])
  end

  private

  def handle_missing_registrar
    @registrar_users = User.none
    @latest_result_by_user_id = {}
    @colleague_rows = []
  end

  def build_latest_result_projection(users)
    users.index_with do |user|
      all = user.test_attempts.to_a
      theoretical = all.select { |a| a.test&.theoretical? }
      practical = all.select { |a| a.test&.practical? }
      {
        theoretical: build_projection_for_attempts(theoretical),
        practical: build_projection_for_attempts(practical)
      }
    end
  end

  def build_colleague_rows(users, projections)
    rows = []
    users.each do |user|
      proj = projections[user] || {}
      %i[theoretical practical].each do |test_type|
        rows << {
          user: user,
          test_type: test_type,
          projection: proj[test_type] || {}
        }
      end
    end
    rows
  end

  def filter_colleague_rows(rows, query)
    q = query.to_s.strip.downcase
    return rows if q.blank?

    rows.select { |row| row_search_blob(row).include?(q) }
  end

  def sort_colleague_rows(rows, sort, direction)
    sort = sort.to_s.strip
    return rows unless RegistrarHelper::REGISTRAR_COLLEAGUES_SORT_COLUMNS.include?(sort)

    asc = direction.to_s.downcase != 'desc'

    rows.sort do |a, b|
      cmp = colleague_row_sort_cmp(a, b, sort, asc)
      cmp = colleague_row_tiebreak_cmp(a, b) if cmp == 0
      cmp
    end
  end

  def colleague_row_sort_cmp(a, b, sort, asc)
    case sort
    when 'name'
      asc ? name_sort_cmp(a, b) : -name_sort_cmp(a, b)
    when 'test_type'
      asc ? test_type_sort_cmp(a, b) : -test_type_sort_cmp(a, b)
    when 'test_title'
      test_title_sort_cmp(a, b, asc)
    when 'workflow'
      asc ? workflow_sort_cmp(a, b) : -workflow_sort_cmp(a, b)
    when 'result'
      asc ? result_sort_cmp(a, b) : -result_sort_cmp(a, b)
    when 'completed_at'
      completed_at_sort_cmp(a, b, asc)
    else
      0
    end
  end

  def colleague_row_tiebreak_cmp(a, b)
    by_user = a[:user].id <=> b[:user].id
    return by_user if by_user != 0

    test_type_sort_cmp(a, b)
  end

  def name_sort_cmp(a, b)
    a[:user].display_name.to_s.downcase <=> b[:user].display_name.to_s.downcase
  end

  def test_type_sort_cmp(a, b)
    test_type_rank(a[:test_type]) <=> test_type_rank(b[:test_type])
  end

  def test_type_rank(sym)
    sym == :theoretical ? 0 : 1
  end

  def test_title_sort_cmp(a, b, asc)
    ta = colleague_row_test_title(a)
    tb = colleague_row_test_title(b)
    ea = ta.strip.empty?
    eb = tb.strip.empty?
    return 0 if ea && eb
    return 1 if ea && !eb
    return -1 if eb && !ea

    asc ? ta.downcase <=> tb.downcase : tb.downcase <=> ta.downcase
  end

  def colleague_row_test_title(row)
    row.dig(:projection, :latest_attempt)&.test&.title.to_s
  end

  def workflow_sort_cmp(a, b)
    ra = workflow_sort_rank(row_projection_result(a))
    rb = workflow_sort_rank(row_projection_result(b))
    ra <=> rb
  end

  def workflow_sort_rank(result)
    case result
    when :not_started then 0
    when :in_progress then 1
    when :passed, :failed, :time_expired then 2
    else 0
    end
  end

  def result_sort_cmp(a, b)
    result_sort_rank(row_projection_result(a)) <=> result_sort_rank(row_projection_result(b))
  end

  def result_sort_rank(result)
    case result
    when :not_started then 0
    when :in_progress then 1
    when :passed then 2
    when :failed then 3
    when :time_expired then 4
    else 0
    end
  end

  def row_projection_result(row)
    row.dig(:projection, :result) || :not_started
  end

  def completed_at_sort_cmp(a, b, asc)
    ta = a.dig(:projection, :completed_at)
    tb = b.dig(:projection, :completed_at)
    na = ta.nil?
    nb = tb.nil?
    return 0 if na && nb
    return 1 if na && !nb
    return -1 if nb && !na

    asc ? ta <=> tb : tb <=> ta
  end

  def row_search_blob(row)
    user = row[:user]
    projection = row[:projection]
    result = projection[:result]
    attempt = projection[:latest_attempt]

    parts = [
      user.display_name,
      user.name,
      user.email,
      I18n.t("admin.tests.index.#{row[:test_type]}"),
      attempt&.test&.title,
      result.to_s,
      workflow_search_terms(result),
      result_search_terms(result)
    ]
    parts.flatten.compact.join(' ').downcase
  end

  def workflow_search_terms(result)
    case result
    when :in_progress
      [I18n.t('registrar.show.workflow_in_progress'), 'in progress', 'pooleli']
    when :passed, :failed, :time_expired
      [I18n.t('registrar.show.workflow_completed'), 'completed', 'lõpetatud']
    else
      [I18n.t('registrar.show.workflow_not_started'), 'not started', 'pole alustatud']
    end
  end

  def result_search_terms(result)
    case result
    when :passed
      [I18n.t('admin.test_attempts.test_attempts_table.passed'), 'passed', 'läbitud']
    when :failed
      [I18n.t('admin.test_attempts.test_attempts_table.failed'), 'failed']
    when :time_expired
      [I18n.t('admin.test_attempts.test_attempts_table.time_expired'), 'time expired', 'aegunud']
    when :in_progress
      [I18n.t('admin.test_attempts.test_attempts_table.in_progress')]
    else
      [I18n.t('admin.test_attempts.test_attempts_table.not_started'), 'not started']
    end
  end

  def build_projection_for_attempts(attempts)
    latest = latest_attempt_for_attempts(attempts)
    {
      latest_attempt: latest,
      status: attempt_status(latest),
      result: attempt_result(latest),
      completed_at: latest&.completed_at
    }
  end

  def latest_attempt_for_attempts(attempts)
    attempts = Array(attempts).compact
    return nil if attempts.empty?

    completed = attempts.select(&:completed?)
    return completed.max_by(&:completed_at) if completed.any?

    active = attempts.select { |attempt| attempt.in_progress? && !attempt.time_expired? }
    return active.max_by { |attempt| attempt.started_at || attempt.created_at } if active.any?

    time_expired = attempts.select { |attempt| time_expired_only?(attempt) }
    if time_expired.any?
      return time_expired.max_by { |attempt| attempt.started_at || attempt.created_at }
    end

    attempts.max_by(&:created_at)
  end

  def time_expired_only?(attempt)
    !attempt.completed? && attempt.time_expired?
  end

  def attempt_status(attempt)
    return :not_started unless attempt
    return :passed if attempt.passed?
    return :failed if attempt.failed?
    return :time_expired if time_expired_only?(attempt)
    return :in_progress if attempt.in_progress?

    :not_started
  end

  def attempt_result(attempt)
    attempt_status(attempt)
  end
end
