require 'singleton'

module Recorder
  module Google
    class Authorizer
      include Singleton

      class << self
        delegate :authorize!, :credentials, :can_authorize?, to: :instance
      end

      OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
      SCOPE = 'https://www.googleapis.com/auth/spreadsheets'.freeze

      def authorize!(user_id = 'default')
        credentials(user_id) || authorize_and_store!(user_id)
      end

      def credentials(user_id = 'default')
        authorizer.get_credentials user_id if can_authorize?
      end

      def can_authorize?
        Recorder.paths.credentials_file.exist?
      end

      private

      def authorize_and_store!(user_id = 'default')
        puts "Google API Credentials not found, starting authorization process..."
        authorizer.get_authorization_url(base_url: OOB_URI).then do |url|
          puts "Steps:"
          puts "  1) Go to #{$pastel.colored_url(url)}"
          puts "  2) Enter code below"
          puts
          $prompter.ask('Auth Code:') do |q|
            q.required true
            q.modify :strip
          end.then do |code|
            authorizer.get_and_store_credentials_from_code(
              user_id: user_id, code: code, base_url: OOB_URI
            )
          end
        end
      end

      def authorizer
        @authorizer ||= ::Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
      end

      def client_id
        @client_id ||= ::Google::Auth::ClientId.from_file(
          Recorder.paths.credentials_file
        )
      end

      def token_store
        @token_store ||= ::Google::Auth::Stores::FileTokenStore.new(
          file: Recorder.paths.token_file
        )
      end
    end
  end
end
