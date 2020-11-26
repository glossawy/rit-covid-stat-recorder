module Recorder
  class CLI
    module Commands
      module Daemon
        class Run < Commands::Command
          desc 'run daemon'

          argument :period, desc: 'iso8601 duration representing frequency of scrape attempts', require: false, default: 'P1H'
          argument :backup_period, desc: 'iso8601 duration representing frequency of db backup', require: false, default: 'P12H'

          def call(period:, backup_period:, **options)
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
                if Time.current >= next_run
                  Recorder.logger.debug("[#{name} daemon] executing #{method}")
                  send(method)
                  next_run = duration.from_now
                  Recorder.logger.debug("[#{name} daemon] next run at: #{next_run.to_formatted_s(:long_ordinal)}")
                else
                  Recorder.logger.debug("[#{name} daemon] skipped, called before next_at at #{next_run.to_formatted_s(:long_ordinal)}")
                end

                Fiber.yield next_run
              end
            end
          end

          def do_fetch!
            cli = Dry::CLI.new(Recorder::CLI::Commands)

            Recorder.logger.info("Doing fetch...")

            begin
              cli.call(arguments: %w[scrape fetch --persist])
              cli.call(arguments: %w[export google])
              Recorder.logger.info('Fetch successful')
            rescue => e
              Recorder.logger.error('Scraping failed with an error')
              Recorder.logger.error(e.full_message)
            end
          end

          def do_backup!
            Recorder.logger.info("Doing backup...")
            ScriptRunner.execute 'backup'
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
