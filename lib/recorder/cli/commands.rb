require 'dry/cli'

module Recorder
  class CLI
    def self.register(name, command = nil, aliases: [], &block)
      Commands.register(name, command, aliases: aliases, &block)
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
    end
  end
end
