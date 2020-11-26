module Recorder
  class CLI
    module Commands
      module Db
        require 'hanami/model'
        require 'hanami/model/sql'
        require 'recorder/cli/commands/db/console'
        require 'recorder/cli/commands/db/create'
        require 'recorder/cli/commands/db/drop'
        require 'recorder/cli/commands/db/migrate'
        require 'recorder/cli/commands/db/prepare'
        require 'recorder/cli/commands/db/version'
        require 'recorder/cli/commands/db/rollback'
      end
    end

    register 'db' do |prefix|
      prefix.register 'console', Commands::Db::Console
      prefix.register 'create', Commands::Db::Create
      prefix.register 'drop', Commands::Db::Drop
      prefix.register 'migrate', Commands::Db::Migrate
      prefix.register 'prepare', Commands::Db::Prepare
      prefix.register 'version', Commands::Db::Version
      prefix.register 'rollback', Commands::Db::Rollback
    end
  end
end
