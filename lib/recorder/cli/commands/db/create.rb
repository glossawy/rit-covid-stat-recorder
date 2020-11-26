module Recorder
  class CLI
    module Commands
      module Db
        class Create < Command
          desc "Create the database"

          def call(**options)
            context = Context.new(options: options)

            create_database(context)
          end

          private

          def create_database(*)
            require 'hanami/model/migrator'
            Hanami::Model::Migrator.create
          end
        end
      end
    end
  end
end
