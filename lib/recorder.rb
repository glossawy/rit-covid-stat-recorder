require 'bundler/setup'

Bundler.require(:default)

require 'active_support/all'
require 'pastel'
require 'tty-prompt'

require 'hanami/logger'
require 'recorder/logging/multi_logger'

require 'recorder/core_ext'
require 'recorder/proc_or_value'
require 'recorder/platform_dependent'
require 'recorder/script_runner'
require 'recorder/notifications'

require 'recorder/entities'
require 'recorder/repositories'
require 'recorder/spiders'

require 'recorder/google'

at_exit do
  if $!.is_a? Recorder::Error
    Recorder.logger.tap do |log|
      err = $!
      log.error("Uncaught #{err.class.name}: #{e.message}")
      err.backtrace.each { |line | log.error(line) }
    end
  end
end

module Recorder
  Error = Class.new(StandardError)
  Absurd = Class.new(Recorder::Error)
  InvalidCredentialsHome = Class.new(Recorder::Error)

  module Paths
    require 'pathname'
    module_function

    def root
      Pathname.new File.expand_path('../', __dir__)
    end

    def db
      root.join 'db'
    end

    def logs
      root.join 'log'
    end

    def scripts
      root.join 'script'
    end

    def credentials_home
      @credentials_home ||=
        (ENV['CREDENTIALS_HOME'] || '.').then do |credentials_home_path|
          Pathname.new(credentials_home_path).then do |p|
            p.absolute? ? p : p.expand_path(Recorder.paths.root)
          end.tap do |p|
            next if p.directory?
            raise Recorder::InvalidCredentialsHome, "#{credentials_home_path} resolves to #{p.to_path} which is not a directory."
          end
        end
    end

    def credentials_file
      credentials_home.join 'credentials.json'
    end

    def token_file
      credentials_home.join 'token.yaml'
    end
  end

  def self.app_name
    ENV.fetch('APP_NAME', 'Covid Stat Recorder')
  end

  def self.app_identifier
    app_name.parameterize
  end

  def self.debug_mode?
    ENV['DEBUG'].then do |debug|
      debug.present? && debug.in?(%w[true 1])
    end
  end

  def self.paths
    self::Paths
  end

  def self.logger
    $recorder_logger
  end

  def self.sheets_api
    Recorder::Google.sheets_api
  end
end

require_relative './config'
require 'recorder/cli/commands'
