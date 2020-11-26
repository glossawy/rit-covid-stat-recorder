require 'os'

class OS
  def self.wsl?
    `cat /proc/version` =~ /Microsoft/ if linux?
  end

  def self.windows_hosted_system?
    windows? || wsl? || Underlying.windows?
  end
end

module Recorder
  class PlatformSwitchPoint < BasicObject
    class Result
      attr_reader :switch_point

      def initialize(switch_point)
        @switch_point = switch_point
      end

      def execute
        call_blocks = [
          (switch_point.on_windows if OS.windows_hosted_system?),
          (switch_point.on_linx if OS.linux?),
          (switch_point.on_wsl if OS.windows_hosted_system?),
        ]

        call_blocks.compact.reduce(&method(:sequence))&.call
      end

      private

      def sequence(a, b)
        lambda do
          a.call
          b.call
        end
      end
    end

    attr_reader :on_windows, :on_linux, :on_wsl

    def on_windows(&block)
      @on_windows = block
    end

    def on_linux(&block)
      @on_linux = block
    end

    def on_wsl(&block)
      @on_wsl = block
    end

    def on_windows_hosted_system(&block)
      @on_windows = block
      @on_wsl = block
    end
  end

  module PlatformDependent
    def on_windows
      yield if OS.windows?
    end

    def on_linux
      yield if OS.linux?
    end

    def on_wsl
      yield if OS.wsl?
    end

    def on_windows_hosted_system
      yield if OS.windows_hosted_system?
    end

    def platform_dependent(&block)
      switch_point = PlatformSwitchPoint.new
      switch_point.instance_eval(&block) if block

      PlatformSwitchPoint::Result.new(switch_point).execute
    end
  end
end