module Recorder
  class CLI
    module Commands
      module Generate
        class Migration < Command
          desc 'Generate a migration'

          argument :migration, require: true, desc: 'The migration name'

          example [
            "create_users # Generate `db/migrations/#{Command.current_migration_timestamp}_create_users.rb`"
          ]

          def call(migration:, **options)
            migration = migration.underscore
            context = Context.new(migration: migration, options: options)

            generate_migration(context)
          end

          private

          def generate_migration(context)
            source = templates.find('migration.erb')
            destination = migration(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end
        end
      end
    end
  end
end