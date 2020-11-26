module Recorder
  class CLI
    module Commands
      module Generate
        class Model < Command
          desc "Generate a model"

          argument :model, required: true, desc: "Model name (eg. `user`)"
          option :skip_migration, type: :boolean, default: false, desc: "Skip migration"
          option :relation, type: :string, desc: "Name of the database relation, default: pluralized model name"

          example [
            "user                     # Generate `User` entity, `UserRepository` repository, and the migration",
            "user --skip-migration    # Generate `User` entity and `UserRepository` repository",
            "user --relation=accounts # Generate `User` entity, `UserRepository` and migration to create `accounts` table"
          ]

          def call(model:, **options)
            model = model.underscore
            relation = relation_name(options, model)
            migration = "create_#{relation}"
            context = Context.new(
              model: model,
              relation: relation,
              migration: migration,
              override_relation: override_relation?(options),
              options: options
            )

            assert_valid_relation!(context)

            generate_entity(context)
            generate_repository(context)
            generate_migration(context)
          end

          private

          def assert_valid_relation!(context)
            if context.relation.blank?
              warn "`#{context.relation}` is not a valid relation name"
e             exit(1)
            end
          end

          def generate_entity(context)
            source = templates.find('entity.erb')
            destination = entity(context)
            
            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_repository(context)
            source = templates.find('repository.erb')
            destination = repository(context)
            
            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_migration(context)
            return if skip_migration?(context)

            source = templates.find('migration.erb')
            destination = migration(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def skip_migration?(context)
            context.options.fetch(:skip_migration, false)
          end

          def relation_name(options, model)
            if override_relation?(options)
              options[:relation].underscore
            else
              model.pluralize
            end
          end

          def override_relation?(options)
            options[:relation].present?
          end
        end
      end
    end
  end
end
