require 'shellwords'

module Recorder
  class CLI
    module Commands
      module Daemon
        class Run < Commands::Command
          desc 'run daemon'

          argument :period, desc: 'iso8601 duration representing frequency of scrape attempts', require: false, default: 'P1H'
          argument :backup_period, desc: 'iso8601 duration representing frequency of db backup', require: false, default: 'P12H'
          option :spider, desc: 'name of spider to use', default: Recorder::Spiders::CURRENT, values: Recorder::Spiders::NAMES_TO_SPIDERS.keys.map(&:to_s)

          def call(period:, backup_period:, spider:, **options)
            @spider_name = spider
            context = Context.new(
              periods: {
                fetch: parse_duration(period),
                backup: parse_duration(backup_period),
              },
              options: options
            )

            start_daemons!(context)
          end

          private

          # There is not really a reason fibers are being used here other than
          # for fun. I guess being able to say "thing.resume" for a scheduling task is neat.
          #
          # This is not any form of parallelism being done here, or even concurrency.
          #
          # The only daemon here is the process as a whole.

          def start_daemons!(context)
            fibers = []

            fibers << timed_daemon_fiber('Fetch', :do_fetch!, context.periods.fetch)
            fibers << timed_daemon_fiber('DB Backup', :do_backup!, context.periods.backup)

            # First run is immediate
            schedule = fibers.map do |fiber|
              [Time.current, fiber]
            end

            loop do
              # Run if next_at is now or past, update next_at if so
              schedule.map! do |(next_at, fiber)|
                if next_at <= Time.current
                  next_at = fiber.resume
                end

                [next_at, fiber]
              end

              # Find nearest next_at and sleep until then
              wait_until = schedule.map(&:first).min
              wait_seconds = [(wait_until - Time.current).to_i + 1, 0].max

              Recorder.logger.debug("Scheduling fiber sleeping for #{wait_seconds} seconds.")
              sleep(wait_seconds)
            end
          rescue Interrupt
            return
          end

          def timed_daemon_fiber(name, method, duration)
            Fiber.new do
              Recorder.logger.info("Initializing #{name} daemon. period = #{duration.iso8601}")

              next_run = Time.current
              loop do
                Recorder.logger.with_prefix(name) do
                  if Time.current >= next_run
                    Recorder.logger.debug("executing #{method}")
                    send(method)
                    next_run = duration.from_now
                    Recorder.logger.debug("next run at: #{next_run.to_formatted_s(:long_ordinal)}")
                  else
                    Recorder.logger.debug("skipped, called before next_at at #{next_run.to_formatted_s(:long_ordinal)}")
                  end
                end
                Fiber.yield next_run
              end
            end
          end

          def do_fetch!
            cli = Dry::CLI.new(Recorder::CLI::Commands)

            Recorder.logger.info("Doing fetch...")

            begin
              fetch_command = %W[scrape fetch --persist --spider=#{@spider_name}]
              Recorder.logger.debug(Shellwords.join([$PROGRAM_NAME, *fetch_command]))
              cli.call(arguments: fetch_command)

              export_command = %w[export google]
              Recorder.logger.debug(Shellwords.join([$PROGRAM_NAME, *export_command]))
              cli.call(arguments: export_command)

              Recorder.logger.info('Scrape successful')
            rescue => e
              Recorder.logger.error('Scraping failed with an error')
              Recorder.logger.error(e.full_message)
            end
          end

          def do_backup!
            Recorder.logger.info("Doing backup...")
            script_output = ScriptRunner.run 'backup'

            Recorder.logger.with_prefix('(shell)') do
              script_output.lines.each do |line|
                Recorder.logger.info line.chomp
              end
            end
          end

          def parse_duration(period)
            period = "P#{period}" unless period.start_with? 'P'
            period = period.sub(/^(P.*?)(\d+[HMS].*)$/i, '\1T\2') if /[HMS]/ =~ period && !period.include?('T')

            ActiveSupport::Duration.parse(period)
          end
        end
      end
    end
  end
end
