module Recorder
  class ProcOrValue
    attr_reader :value

    delegate :to_proc, to: :value
    delegate :call, to: :value

    def initialize(proc_or_value)
      @value = proc_or_value
    end

    def call_or_get(*args)
      case value
      when Proc
        call(*args)
      else
        value
      end
    end
  end
end
