module Recorder
  class CLI
    module Commands
      module Scrape
        require 'recorder/cli/commands/scrape/command'
        require 'recorder/cli/commands/scrape/fetch'
      end
    end

    register 'scrape', aliases: ['s'] do |prefix|
      prefix.register 'fetch', Commands::Scrape::Fetch
    end
  end
end
