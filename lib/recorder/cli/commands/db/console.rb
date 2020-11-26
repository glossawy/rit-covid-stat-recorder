module Recorder
  class CLI
    module Commands
      module Db
        class Console < Command
          desc 'Starts a database console'

          def call(**options)
            context = Context.new(options: options)
            
            start_console(context)
          end

          private

          def start_console(*)
            exec console.connection_string
          end

          def console
            require 'hanami/model/sql/console'
            Hanami::Model::Sql::Console.new(DATABASE_URL)
          end
        end
      end
    end
  end
end
