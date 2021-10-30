require 'dry/cli'

class Dry::CLI
  private

  def perform_command(arguments)
    command, args = parse(kommand, arguments, [])
    # call .perform instead of .call
    command.perform(**args)
  end

  def perform_registry(arguments)
    result = registry.get(arguments)

    if result.found?
      command, args = parse(result.command, result.arguments, result.names)

      result.before_callbacks.run(command, args)
      command.perform(**args)
      result.after_callbacks.run(command, args)
    else
      usage(result)
    end
  end
end

module Recorder
  class CLI
    def self.register(name, command = nil, aliases: [], &block)
      Commands.register(name, command, aliases: aliases, &block)
    end

    def self.run
      Dry::CLI.new(self::Commands).call
    end

    module Commands
      extend Dry::CLI::Registry

      class Context
        attr_reader :data

        def initialize(data)
          @data = contextify(data)

          setup_methods!
          freeze
        end

        def with(data)
          self.class.new(to_h.merge(data))
        end

        def to_h
          data.dup
        end
        alias to_hash to_h

        def logger
          Recorder.logger
        end

        def binding
          super
        end

        private

        def contextify(hsh)
          hsh.transform_values do |value|
            if value.instance_of? Hash
              Context.new(value)
            else
              value
            end
          end
        end

        def setup_methods!
          data.each do |key, value|
            singleton_class.class_eval do
              define_method(key.to_s.underscore) { value }
            end
          end
        end
      end

      require 'recorder/cli/commands/command'
      require 'recorder/cli/commands/db'
      require 'recorder/cli/commands/generate'
      require 'recorder/cli/commands/scrape'
      require 'recorder/cli/commands/export'
      require 'recorder/cli/commands/daemon'
      require 'recorder/cli/commands/import'
    end

    require 'recorder/cli/commands/authorize'

    register 'authorize', Commands::Authorize
  end
end
