# Custom formatter for logging output in JSON format
class JsonLogFormatter < Logger::Formatter
  def call(severity, timestamp, progname, msg)
    {
      timestamp: timestamp.utc.iso8601,
      severity: severity,
      program_name: progname,
      message: msg.is_a?(String) ? msg : msg.inspect,
      pid: Process.pid,
      environment: Rails.env
    }.to_json + "\n"
  end
end
