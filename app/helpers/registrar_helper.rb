module RegistrarHelper
  REGISTRAR_COLLEAGUES_SORT_COLUMNS = %w[name test_type test_title workflow result completed_at].freeze

  def registrar_colleagues_sort_link(column, label)
    column = column.to_s
    unless REGISTRAR_COLLEAGUES_SORT_COLUMNS.include?(column)
      return label
    end

    current_sort = params[:sort].to_s
    current_dir = params[:direction].to_s.downcase
    current_dir = 'asc' if current_dir != 'desc'

    next_direction =
      if current_sort == column
        current_dir == 'asc' ? 'desc' : 'asc'
      else
        'asc'
      end

    css = ['sort_link']
    css << current_dir if current_sort == column

    link_to(
      label,
      registrar_path(registrar_colleagues_index_params(sort: column, direction: next_direction)),
      class: css.join(' ')
    )
  end

  def registrar_colleagues_index_params(overrides = {})
    out = {}
    out[:q] = params[:q] if params[:q].present?
    out[:sort] = params[:sort] if params[:sort].present?
    out[:direction] = params[:direction] if params[:direction].present?
    out.merge(overrides)
  end
end
