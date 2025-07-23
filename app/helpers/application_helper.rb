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

  private

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
    [{ name: I18n.t('nav.dashboard'), path: admin_dashboard_path },
     { name: I18n.t('nav.tests'), path: admin_tests_path },
     { name: I18n.t('nav.test_categories'), path: admin_test_categories_path }]
  end
end
