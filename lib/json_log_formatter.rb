# Custom formatter for logging output in JSON format
class JsonLogFormatter < Logger::Formatter
  def call(severity, timestamp, progname, msg)
    tags = current_tags_list
    message = msg.is_a?(String) ? msg : msg.inspect

    {
      timestamp: timestamp.utc.iso8601,
      severity: severity,
      program_name: progname,
      message: message,
      tags: tags,
      request_id: extract_request_id(tags),
      remote_ip: extract_remote_ip(tags),
      pid: Process.pid,
      environment: Rails.env
    }.to_json + "\n"
  end

  private

  def current_tags_list
    return [] unless respond_to?(:current_tags)

    Array(current_tags).map(&:to_s)
  end

  def extract_request_id(tags)
    tags.find { |tag| tag.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i) }
  end

  def extract_remote_ip(tags)
    tags.find { |tag| tag.match?(/\A(?:\d{1,3}\.){3}\d{1,3}\z/) || tag.include?(':') }
  end
end
