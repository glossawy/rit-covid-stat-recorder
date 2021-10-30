module Recorder
  class CLI
    module Commands
      class Command < Dry::CLI::Command
        attr_reader :templates

        class_attribute :skip_debug_info, instance_accessor: false, default: false

        def initialize
          require 'recorder/cli/commands/templates'
          @templates = Templates.new(self.class)
        end

        def perform(*args, **kwargs)
          print_debug_info unless self.class.skip_debug_info?
          call(*args, **kwargs)
        end

        private

        class Renderer
          def initialize
            freeze
          end

          def call(template, context)
            ::ERB.new(template, nil, "-").result(context)
          end
        end

        SAY_FORMATTER = "%<operation>s %<path>s".freeze

        def render(path, context)
          template = File.read(path)
          Renderer.new.call(template, context.binding)
        end

        def generate_file(source, destination, context)
          Pathname.new(destination).dirname.mkpath

          output = render(source, context)
          File.open(destination, File::CREAT | File::WRONLY | File::TRUNC) do |file|
            file.write(Array(output).flatten.join)
          end
        end

        def info(*args)
          args << '' if args.empty?
          Recorder.logger.info(*args)
        end

        def debug(*args)
          args << '' if args.empty?
          Recorder.logger.debug(*args)
        end

        def print_debug_info_helper(name, value, indent: '', padout: 0)
          case value
          when Hash
            debug("#{indent}#{name.rjust(padout, ' ')}:")
            new_indent = "#{indent}  "; new_padout = value.keys.map(&:size).max
            value.each { |k, v| print_debug_info_helper(k, v, indent: new_indent, padout: new_padout) }
          else
            debug("#{indent}#{name.rjust(padout, ' ')}: #{value}")
          end
        end

        def print_debug_info
          return unless Recorder.debug_mode?

          print_debug_info_helper(
            'paths',
            {
              'root' => Recorder.paths.root,
              'logs' => Recorder.paths.logs,
              'data' => Recorder.paths.db,
              'auth' => {
                'home' => Recorder.paths.credentials_home,
                'creds' => Recorder.paths.credentials_file,
                'token' => Recorder.paths.token_file,
              },
            }
          )
        end

        def say(operation, path)
          operations = operation.to_s.split('>').map(&:strip)
          operations[-1] = "#{operations[-1]}:"

          operation = operations.map { |op| $pastel.say_op(op) }.join($pastel.say_op_sep(' ➔ '))

          info(SAY_FORMATTER % { operation: operation, path: path })
        end

        def collection_attempt_repo
          Repositories::CollectionAttemptRepository.new
        end

        def covid_stat_repo
          Repositories::CovidStatRepository.new
        end

        def covid_stats
          covid_stat_repo.with_attempts
        end

        def most_recent_stat
          covid_stat_repo.most_recent
        end

        def rit_updated_at
          most_recent_stat&.last_updated_at || Time.utc(1970)
        end

        def stats_sheet
          require 'recorder/cli/commands/stat_sheet'
          @stats_sheet ||= StatSheet.new
        end

        class << self
          def root
            Recorder.paths.root
          end

          def migrations
            Recorder.paths.db.join('migrations')
          end

          def migration(context)
            filename = "%{timestamp}_%{name}" % { timestamp: current_migration_timestamp, name: context.migration }
            migrations.join("#{filename}.rb")
          end

          def find_migration(context)
            Dir.glob(migrations.join("*_#{context.migration}.rb")).sort!.first
          end

          def current_migration_timestamp
            Time.now.utc.strftime('%Y%m%d%H%M%S')
          end

          def entity(context)
            root.join('lib', 'recorder', 'entities', "#{context.model}.rb")
          end

          def repository(context)
            root.join('lib', 'recorder', 'repositories', "#{context.model}_repository.rb")
          end

          def stats_sheet
            require 'recorder/cli/commands/stat_sheet'
            StatSheet.new
          end
        end

        require 'forwardable'
        extend Forwardable
        def_delegators :'self.class', *%i[
          root
          migrations
          migration
          find_migration
          current_migration_timestamp
          entity
          repository
        ]
      end
    end
  end
end
