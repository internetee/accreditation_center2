module TestsHelper
  def format_duration(total_seconds)
    return '0s' if total_seconds.blank? || total_seconds.to_i <= 0

    total_seconds = total_seconds.to_i
    hours = total_seconds / 3600
    minutes = (total_seconds % 3600) / 60
    seconds = total_seconds % 60

    parts = []
    parts << "#{hours}h" if hours.positive?
    parts << "#{minutes}m" if minutes.positive? || hours.positive?
    parts << "#{seconds}s"
    parts.join(' ')
  end
end
