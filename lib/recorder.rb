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

module Recorder
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
  end

  def self.app_name
    ENV.fetch('APP_NAME', 'Covid Stat Recorder')
  end

  def self.app_identifier
    app_name.parameterize
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
