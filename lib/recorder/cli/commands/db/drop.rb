module Recorder
  class CLI
    module Commands
      module Db
        class Drop < Command
          desc "Drop the database"

          def call(**options)
            context = Context.new(options: options)

            drop_database(context)
          end

          private

          def drop_database(*)
            require 'hanami/model/migrator'
            Hanami::Model::Migrator.drop
          end
        end
      end
    end
  end
end