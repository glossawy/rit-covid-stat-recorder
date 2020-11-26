module Recorder
  class CLI
    module Commands
      module Daemon
        require 'recorder/cli/commands/daemon/run'
      end

      register 'daemon' do |prefix|
        prefix.register 'run', Commands::Daemon::Run
      end
    end
  end
end
