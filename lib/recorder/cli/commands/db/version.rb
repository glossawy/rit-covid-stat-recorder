module Recorder
  class CLI
    module Commands
      module Db
        class Version < Command
          desc "Print version of current migration"

          def call(**options)
            context = Context.new(options: options)

            print_db_verison(context)
          end

          private

          def print_db_verison(*)
            require 'hanami/model/migrator'
            puts Hanami::Model::Migrator.version
          end
        end
      end
    end
  end
end