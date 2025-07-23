module TestsHelper
  def format_duration(seconds)
    hours = (seconds / 3600).floor
    minutes = ((seconds % 3600) / 60).floor
    remaining_seconds = seconds % 60
    
    if hours > 0
      "#{hours}h #{minutes}m #{remaining_seconds}s"
    elsif minutes > 0
      "#{minutes}m #{remaining_seconds}s"
    else
      "#{remaining_seconds}s"
    end
  end
  
  def calculate_category_score(responses)
    return 0 if responses.empty?
    
    correct_count = responses.count(&:correct?)
    (correct_count.to_f / responses.count * 100).round(1)
  end
  
  def question_status_icon(response)
    case response&.status
    when 'correct'
      content_tag(:i, '', class: 'fas fa-check text-success')
    when 'incorrect'
      content_tag(:i, '', class: 'fas fa-times text-danger')
    when 'marked_for_later'
      content_tag(:i, '', class: 'fas fa-clock text-warning')
    else
      content_tag(:i, '', class: 'fas fa-minus text-secondary')
    end
  end
  
  def answer_status_class(answer, response)
    classes = []
    classes << 'correct' if answer.correct?
    classes << 'selected' if response&.selected_answer_ids&.include?(answer.id)
    classes.join(' ')
  end
  
  def time_warning_class(test_attempt)
    'warning' if test_attempt.time_warning?
  end
  
  def progress_color_class(percentage)
    if percentage >= 80
      'success'
    elsif percentage >= 60
      'warning'
    else
      'danger'
    end
  end
end 