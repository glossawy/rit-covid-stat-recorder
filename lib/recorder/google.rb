require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google/apis/sheets_v4'

require_relative './google/authorizer'

module Recorder
  module Google
    class << self
      delegate :authorize!, :credentials, :can_authorize?, to: Recorder::Google::Authorizer

      def authorized?
        can_authorize? && credentials.present?
      end

      def sheets_api
        @sheets_api ||=
          ::Google::Apis::SheetsV4::SheetsService.new.tap do |svc|
            svc.client_options.application_name = Recorder.app_name
            svc.authorization = authorize!
          end
      end
    end
  end
end
