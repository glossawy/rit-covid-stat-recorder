ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

DATABASE_PATH = Recorder.paths.db.join 'stats.sqlite3'
DATABASE_URL = "sqlite://#{DATABASE_PATH}"

MIGRATIONS_DIR = Recorder.paths.db.join 'migrations'

APP_LOG_PATH = Recorder.paths.logs.join 'app.log'
DB_LOG_PATH = Recorder.paths.logs.join 'database.log'

TZ_IDENTIFIER = ENV.fetch('TIME_ZONE', 'UTC')

Hanami::Model.configure do |c|
  adapter :sql, DATABASE_URL
  migrations MIGRATIONS_DIR

  logger DB_LOG_PATH, level: :debug
  @_logger.application_name = Recorder.app_identifier
end.load!

Time.zone_default = Time.find_zone TZ_IDENTIFIER

$recorder_logger = Recorder::Logging::MultiLogger.new(
  loggers: [
    Hanami::Logger.new('recorder'),
    Hanami::Logger.new('recorder', stream: APP_LOG_PATH)
  ]
)

$pastel = Pastel.new.tap do |p|
  p.alias_color(:colored_url, :bright_blue)
end

$prompter = TTY::Prompt.new

Kimurai.configure do |c|
  c.time_zone = TZ_IDENTIFIER
  c.logger = $recorder_logger
end
