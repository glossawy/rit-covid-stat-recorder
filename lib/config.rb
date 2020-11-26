ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

DATABASE_PATH = File.expand_path('../db/stats.sqlite3', __dir__)
DATABASE_URL = "sqlite://#{DATABASE_PATH}"
APP_LOG_PATH = File.expand_path('../log/app.log', __dir__)
DB_LOG_PATH = File.expand_path('../log/database.log', __dir__)
MIGRATIONS_PATH = File.expand_path('../db/migrations', __dir__)

TZ_IDENTIFIER = 'America/New_York'
GOOGLE_SHEET_ID = '1ioVXMXLKQwNv8b8u3yqYq5HoF69V7PIrcThrLwNY2gc'
GOOGLE_SHEET_NAME = 'Data'

Hanami::Model.configure do |c|
  adapter :sql, DATABASE_URL
  migrations MIGRATIONS_PATH

  logger DB_LOG_PATH, level: :debug
  @_logger.application_name = 'rit-covid-recorder'
end.load!

Time.zone_default = Time.find_zone TZ_IDENTIFIER

$recorder_logger = Recorder::Logging::MultiLogger.new(
  loggers: [
    Hanami::Logger.new('recorder'),
    Hanami::Logger.new('recorder', stream: APP_LOG_PATH)
  ]
)

Kimurai.configure do |c|
  c.time_zone = TZ_IDENTIFIER
  c.logger = $recorder_logger
end
