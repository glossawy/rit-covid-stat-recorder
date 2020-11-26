module Recorder
  class CLI
    module Commands
      module Export
        require 'recorder/cli/commands/export/csv'
        require 'recorder/cli/commands/export/google'
      end
    end

    register 'export', aliases: %w[ex] do |prefix|
      prefix.register 'csv', Commands::Export::Csv
      prefix.register 'google', Commands::Export::Google, aliases: ['gg']
    end
  end
end
