module Recorder
  class CLI
    module Commands
      class Templates
        NAMESPACE = name.sub(name.demodulize, '').freeze

        attr_reader :root

        def initialize(klass)
          rel_path = klass.name.sub(NAMESPACE, '').split('::').map(&:downcase)
          @root = Pathname.new(File.join(__dir__, *rel_path))
          freeze
        end

        def find(*path)
          @root.join(*path)
        end
      end
    end
  end
end
