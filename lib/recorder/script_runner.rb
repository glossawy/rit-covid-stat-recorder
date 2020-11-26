require 'shellwords'

module Recorder
  module ScriptRunner
    include PlatformDependent

    def self.script_root
      Recorder.paths.scripts
    end

    def self.script_path(name)
      Shellwords.escape(script_root.join(name).relative_path_from(Dir.pwd).to_path)
    end

    def self.build_command(script_name, *args, using: '')
      "#{using} #{script_path script_name} #{Shellwords.shelljoin args}".strip
    end

    def self.execute(script_name, *args, using: '')
      system build_command(script_name, *args, using: using)
    end

    def self.run(script_name, *args, using: '')
      %x{#{build_command script_name, *args, using: using}}
    end
  end
end
