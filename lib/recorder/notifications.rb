require 'shellwords'

module Recorder
  module Notifications
    include Recorder::PlatformDependent

    NEW_STATISTIC = 'New-Statistic'
    ERROR = 'Error'

    def self.notify!(type)
      on_windows_hosted_system do
        Recorder::ScriptRunner.run 'notify.ps1', type, using: 'powershell.exe'
      end
    end

    def self.new_statistic!
      notify! NEW_STATISTIC
    end

    def self.error!
      notify! ERROR
    end
  end
end
