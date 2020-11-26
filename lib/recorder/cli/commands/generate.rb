module Recorder
  class CLI
    module Commands
      module Generate
        require 'recorder/cli/commands/generate/migration'
        require 'recorder/cli/commands/generate/model'
      end
    end

    register 'generate', aliases: ['g'] do |prefix|
      prefix.register 'migration', Commands::Generate::Migration
      prefix.register 'model', Commands::Generate::Model
    end
  end
end
