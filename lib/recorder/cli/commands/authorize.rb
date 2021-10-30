module Recorder
  class CLI
    module Commands
      class Authorize < Commands::Command
        desc 'Collect google auth credentials'

        self.skip_debug_info = true

        option :home, desc: 'Path to store credentials', require: true
        option :force, desc: 'Force new credentials', require: false, type: :boolean, default: false

        def call(home:, force:, **options)
          context = Context.new(
            credentials_home: home,
            clean?: force,
            options: options
          )

          set_env!(context)

          print_debug_info

          return if force && $prompter.no?('Credentials WILL be deleted. Continue?')

          prepare!(context)
          authorize!(context)
        end

        private

        def set_env!(context)
          say 'write', "CREDENTIALS_HOME=#{context.credentials_home}"
          ENV['CREDENTIALS_HOME'] = context.credentials_home
        end

        def prepare!(context)
          raise "Can't authorize, make sure #{Recorder.paths.credentials_file} exists" unless Google.can_authorize?

          if context.clean?
            say 'clean', Recorder.paths.credentials_home.to_path

            [
              Recorder.paths.token_file
            ].select(&:exist?).each do |file|
              say 'clean > delete', file.basename
              file.delete
            end
          end
        end

        def authorize!(_context)
          say 'authorize', 'start'

          if Google.authorized?
            say 'authorize', 'credentials already exist!'
          else
            Google.authorize!
          end
          say 'authorize', 'complete'
        end
      end
    end
  end
end
