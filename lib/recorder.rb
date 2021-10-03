require 'bundler/setup'

Bundler.require(:default)

require 'active_support/all'
require 'google/apis/sheets_v4'

require 'hanami/logger'
require 'recorder/logging/multi_logger'

require 'recorder/core_ext'
require 'recorder/platform_dependent'
require 'recorder/script_runner'
require 'recorder/notifications'

require 'recorder/entities'
require 'recorder/repositories'
require 'recorder/spiders'

require_relative './config'

require 'recorder/cli/commands'

module Recorder
  module Paths
    require 'pathname'
    module_function

    def root
      Pathname.new File.expand_path('../', __dir__)
    end

    def scripts
      root.join 'script'
    end
  end

  def self.paths
    self::Paths
  end

  def self.logger
    $recorder_logger
  end

  def self.sheets_api
    @sheets ||= begin
      Google::Apis::SheetsV4::SheetsService.new.tap do |svc|
        svc.client_options.application_name = APPLICATION_NAME
        svc.authorization = authorize
      end
    end
  end

  require 'googleauth'
  require 'googleauth/stores/file_token_store'

  OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
  APPLICATION_NAME = "RIT Covid Stat Scraper".freeze
  CREDENTIALS_PATH = File.expand_path('../credentials.json', __dir__).freeze
  TOKEN_PATH = File.expand_path('../token.yaml', __dir__).freeze
  SCOPE = 'https://www.googleapis.com/auth/spreadsheets'.freeze

  private

  def self.authorize
    client_id = Google::Auth::ClientId.from_file CREDENTIALS_PATH
    token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH
    authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store

    user_id = 'default'
    credentials = authorizer.get_credentials user_id
    if credentials.nil?
      url = authorizer.get_authorization_url base_url: OOB_URI
      puts "Re-authorize, provide code: #{url}"
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )
    end
    credentials
  end
end
