module Recorder
  class CLI
    module Commands
      module Import
        require 'recorder/cli/commands/import/rit-covid-dashboard-api'
      end
    end

    register 'import', aliases: ['i'] do |prefix|
      prefix.register 'rit-covid-dashboard-api', Commands::Import::RitCovidDashboardApi, aliases: ['api', 'rcd-api']
    end
  end
end
