require 'json'

module Recorder
  class CLI
    module Commands
      module Import
        class RitCovidDashboardApi < Command
          desc "Fetch and get missing data from ritcoviddashboard.com api"

          SPRING_FALL_CUTOFF = Time.zone.parse('2020-01-22')

          LEVEL_TRANSFORM_FALL = {
            'green' => 'Green (Low Risk with Vigilance)',
            'yellow' => 'Yellow (Low to Moderate Risk)',
            'orange' => 'Orange (Moderate Risk)',
            'red' => 'Red (High Risk)',
          }

          LEVEL_TRANSFORM_SPRING = {
            'green' => 'Green (Low Risk with Vigilance)',
            'yellow' => 'Yellow (Moderate Risk)',
            'orange' => 'Orange (Moderate to High Risk)',
            'red' => 'Red (High to Severe Risk)',
          }

          ITEM_TRANSFORM = {
            alert_level: ->(v, time) {
              status =
                if time <= SPRING_FALL_CUTOFF
                  LEVEL_TRANSFORM_FALL[v]
                else
                  LEVEL_TRANSFORM_SPRING[v]
                end

              { campus_status: status  }
            },
            beds_available: :isolation_bed_availability,
            isolation_off_campus: :isolated_off_campus,
            isolation_on_campus: :isolated_on_campus,
            quarantine_off_campus: :quarantined_off_campus,
            quarantine_on_campus: :quarantined_on_campus,
            last_updated: ->(v, _) {
              { last_updated_at: Time.zone.parse(v).to_date }
            },
            new_staff: :new_cases_employees,
            new_students: :new_cases_students,
            tests_administered: :tests_to_date,
            total_staff: :total_cases_employees,
            total_students: :total_cases_students,
          }

          option :reason, type: :string, required: true, desc: 'Reason for restoration'
          option :persist, type: :boolean, default: false, desc: 'Persist stats to db'

          def call(reason:, persist:, **options)
            context = Context.new(
              persist?: persist,
              reason: reason,
              restored_at: Time.current.to_formatted_s(:short),
              options: options
            )

            stats_by_date = stats.group_by { |stat| stat.last_updated_at.to_date.to_formatted_s(:db) }

            new_stats = api_data.reject do |item|
              # Reject dates for which we have a record
              key = item[:last_updated].split(' ').first.strip
              stats_by_date.key?(key)
            end.map { |item| transform_item_to_stat(item) }

            new_stats.each do |cstat|
              fields = cstat.to_h.keys.sort
              padding = fields.map(&:size).max + 1

              fields.each do |field|
                info("%<field>#{padding}s: %<value>s" % { field: field, value: cstat.send(field) })
              end
              info

              if context.persist?
                covid_stat_repo.success(
                  cstat,
                  reason: context.reason,
                  note: "Restored from ritcoviddashboard.com's API #{context.restored_at}."
                )
              end
            end

            if context.persist?
              info "Found and persisted #{new_stats.size} entries"
            else
              info "Found #{new_stats.size} entries to import"
            end
          end

          private

          def transform_item_to_stat(item)
            statistic = {}
            recorded_on = Time.zone.parse(item[:last_updated])
            item.each do |k, v|
              transform = ITEM_TRANSFORM[k]
              next unless transform

              case transform
              when Proc
                statistic.merge!(transform.call(v, recorded_on))
              when Symbol
                statistic[transform] = v
              end
            end

            statistic.merge!(
              surveillance_positive_ratio: -1,
              recorded_at: recorded_on,
            )

            Recorder::Entities::CovidStat.new(statistic)
          end

          def api_data
            @api_data ||=
              begin
                response = HTTParty.get('https://ritcoviddashboard.com/api/v0/history', format: :plain)
                JSON.parse(response).map(&:deep_symbolize_keys)
              end
          end

          def stats
            @stats ||= covid_stat_repo.with_attempts
          end
        end
      end
    end
  end
end
