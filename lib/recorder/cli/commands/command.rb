module Recorder
  class CLI
    module Commands
      class Command < Dry::CLI::Command
        attr_reader :templates

        def initialize
          require 'recorder/cli/commands/templates'
          @templates = Templates.new(self.class) 
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
  
        SAY_FORMATTER = "%<operation>12s %<path>s\n".freeze

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

        def say(operation, path)
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
          most_recent_stat.last_updated_at
        end

        def stats_sheet
          require 'recorder/cli/commands/stat_sheet'
          @stats_sheet ||= StatSheet.new
        end
        
        class << self 
          def root
            File
          end
  
          def migrations
            root.join('db', 'migrations')
          end
  
          def migration(context)
            filename = "%{timestamp}_%{name}" % { timestamp: current_migration_timestamp, name: context.migration }
            root.join('db', 'migrations', "#{filename}.rb")
          end
          
          def find_migration(context)
            Dir.glob(root.join('db', 'migrations', "*_#{context.migration}.rb")).sort!.first
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
