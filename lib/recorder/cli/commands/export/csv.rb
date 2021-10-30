module Recorder
  class CLI
    module Commands
      module Export
        class Csv < Command
          desc 'Export current data in csv format'

          option :pretty, type: :boolean, default: false, desc: 'print csv as neato table'

          def call(pretty:, **options)
            context = Context.new(pretty: pretty, options: options)

            export_csv(context)
          end

          private

          ORDERING = {
            recorded_at: :localtime.to_proc,
            last_updated_at: :to_date.to_proc,
            campus_status: nil,
            new_cases_students: nil,
            new_cases_employees: nil,
            num_days_included: nil,
            total_cases_students: nil,
            total_cases_employees: nil,
            quarantined_on_campus: nil,
            quarantined_off_campus: nil,
            isolated_on_campus: nil,
            isolated_off_campus: nil,
            tests_to_date: nil,
            isolation_bed_availability: nil,
            surveillance_positive_ratio: nil,
          }

          def export_csv(context)
            output = 
              if context.pretty
                render_table
              else
                render_plain
              end

            puts output
          end

          def render_table
            require 'tabulo'
            Tabulo::Table.new(all_stats, *ORDERING.keys, border: :modern).pack
          end

          def render_plain
            require 'csv'
            io = StringIO.new
            csv = CSV.new(io)

            csv << ORDERING.keys.map(&:to_s)
            rows.each do |row|
              csv << row
            end

            io.string
          end

          def all_stats
            @all_stats ||= Repositories::CovidStatRepository.new.with_attempts
          end

          def rows
            all_stats.map do |stat|
              ORDERING.map do |field, fn|
                fn ||= :itself.to_proc

                fn.call stat.public_send(field)
              end
            end
          end
        end
      end
    end
  end
end
