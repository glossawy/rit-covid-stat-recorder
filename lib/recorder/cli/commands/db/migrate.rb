module Recorder
  class CLI
    module Commands
      module Db
        class Migrate < Command
          desc 'Migrate database'

          argument :version, desc: 'The target version of the migration'

          example [
            "               # Migrate to the last version",
            "#{Command.current_migration_timestamp} # Migrate to a specific version"
          ]

          def call(version: nil, **options)
            context = Context.new(version: version, options: options)

            migrate_database(context)
          end

          private

          def migrate_database(context)
            require 'hanami/model/migrator'
            Hanami::Model::Migrator.migrate(version: context.version)
          end
        end
      end
    end
  end
end
