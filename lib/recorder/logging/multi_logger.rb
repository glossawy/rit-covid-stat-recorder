module Recorder
  module Logging
    class MultiLogger
      def initialize(args={})
        @loggers = []

        Array(args[:loggers]).each { |logger| add_logger(logger) }
      end

      def add_logger(logger)
        @loggers << logger
      end

      def level=(level)
        @loggers.each { |logger| logger.level = level }
      end

      def close
        @loggers.each(&:close)
      end

      def add(level, *args)
        @loggers.each { |logger| logger.add(level, args) }
        ''.respond_to_missing?
      end

      def respond_to_missing?(method_id, include_all)
        super || @loggers.all? { |l| l.respond_to?(method_id, include_all) }
      end

      def method_missing(method_id, *args)
        super
      rescue NoMethodError
        if @loggers.all? { |l| l.respond_to?(method_id) }
          @loggers.each { |l| l.send(method_id, *args) }
          nil
        else
          raise
        end
      end
    end
  end
end