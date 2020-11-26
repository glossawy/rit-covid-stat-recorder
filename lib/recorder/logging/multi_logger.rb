module Recorder
  module Logging
    class MultiLogger
      def initialize(args={})
        Array(args[:loggers]).each { |logger| add_logger(logger) }
      end

      def loggers
        @loggers ||= []
      end

      def add_logger(logger)
        loggers << logger
      end

      def level=(level)
        loggers.each { |logger| logger.level = level }
      end

      def close
        loggers.each(&:close)
      end

      def add_prefix(prefix)
        prefixes << prefix
      end

      def prefixes
        @prefix ||= []
      end

      def with_prefix(*prefixes)
        prefixes.each(&method(:add_prefix))
        yield
      ensure
        prefixes.length.times { self.prefixes.pop }
      end

      private

      def get_prefix
        path = prefixes.join " > "
        "[#{path}]"
      end

      def respond_to_missing?(method_id, include_all)
        super || @loggers.all? { |l| l.respond_to?(method_id, include_all) }
      end

      def method_missing(method_id, *args)
        super
      rescue NoMethodError
        if @loggers.all? { |l| l.respond_to?(method_id) }
          if prefixes.present?
            args.unshift "#{get_prefix} #{args.shift}"
          end
          @loggers.each { |l| l.send(method_id, *args) }
          nil
        else
          raise
        end
      end
    end
  end
end