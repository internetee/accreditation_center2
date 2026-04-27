module ApplicationHelper
  include Pagy::Frontend

  def back_link(options = {})
    link_to options[:path] || :back, class: 'back-link', data: { turbo: false } do
      out = []
      out << tag.i(nil, class: 'fas fa-arrow-left')
      out << tag.span(options[:text] || t(:back))
      safe_join(out)
    end
  end

  def navigation_links(current_user)
    tag.ul do
      if current_user&.admin?
        links(administrator_link_list)
      else
        links(user_link_list)
      end
    end
  end

  def dynamic_select_tag(method, choices, options = {})
    options[:itemSelectText] ||= t(:press_to_select)
    options[:noChoicesText] ||= t(:start_typing)
    options[:allowHTML] = true
    select_tag(method, choices, options)
  end

  def simple_select_tag(method, choices, options = {})
    options[:itemSelectText] ||= t(:press_to_select)
    options[:allowHTML] = true
    select_tag(method, choices, options)
  end

  def icon_link_to(cls, url, html_options = {})
    link_to(url, html_options) do
      tag.i(nil, class: cls)
    end
  end

  def render_markdown(text)
    return ''.html_safe if text.blank?

    html = Kramdown::Document.new(text.to_s, hard_wrap: true).to_html
    sanitize(
      html,
      tags: %w[p br strong em a ul ol li h1 h2 h3 h4 blockquote code pre hr],
      attributes: %w[href title]
    )
  end

  def render_practical_task_body(body, vars = {})
    rendered = vars.present? ? Mustache.render(body.to_s, vars) : body.to_s
    render_markdown(rendered)
  end

  def practical_task_result_status_badge(status, label = nil)
    css_variant = practical_task_result_status_variant(status)
    content_tag(:span, label || status.to_s.humanize, class: "label label-#{css_variant}")
  end

  private

  def practical_task_result_status_variant(status)
    case status.to_s
    when 'passed'
      'success'
    when 'failed'
      'danger'
    when 'pending'
      'warning'
    when 'running'
      'info'
    else
      'default'
    end
  end

  def links(links_list)
    links_list.each do |item|
      concat(
        tag.li do
          link_to(
            item[:name],
            item[:path],
            method: item[:method],
            data: item[:data],
            class: ('selected' if current_page?(item[:path]))
          )
        end
      )
    end
  end

  def user_link_list
    [{ name: I18n.t('nav.dashboard'), path: root_path }]
  end

  def administrator_link_list
    [
      { name: I18n.t('nav.dashboard'), path: admin_dashboard_path },
      { name: I18n.t('nav.tests'), path: admin_tests_path },
      { name: I18n.t('nav.test_categories'), path: admin_test_categories_path },
      { name: I18n.t('nav.users'), path: admin_users_path },
      { name: I18n.t('nav.registrars'), path: admin_registrars_path },
      { name: I18n.t('nav.jobs'), path: admin_jobs_path }
    ]
  end
end
