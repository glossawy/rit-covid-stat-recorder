module Recorder
  class CLI
    module Commands
      module Db
        class Rollback < Command
          desc "Rollback migrations"

          argument :steps, desc: "Number of steps to rollback the database", default: 1

          example [
            "  # Rollbacks latest migration",
            "2 # Rollbacks last two migrations"
          ]

          def call(steps:, **)
            context = Context.new(steps: steps)
            context = assert_valid_steps!(context)

            rollback_database(context)
          end

          private

          def assert_valid_steps!(context)
            context = context.with(steps: Integer(context.steps.to_s))
            handle_error(context) unless context.steps.positive?
            context
          rescue TypeError
            handle_error(context)
          end

          def rollback_database(context)
            require "hanami/model/migrator"
            Hanami::Model::Migrator.rollback(steps: context.steps)
          end

          def handle_error(context)
            warn "the number of steps must be a positive integer (you entered `#{context.steps}')."
            exit(1)
          end
        end
      end
    end
  end
end