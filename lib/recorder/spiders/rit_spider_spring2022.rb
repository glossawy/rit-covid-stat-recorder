module Recorder::Spiders
  class RitSpiderSpring2022 < RitSpiderBase
    self.dashboard_url = 'https://www.rit.edu/ready/spring-2022-dashboard'

    LAST_TOTALS_FALL = {
      total_cases_students: 790,
      total_cases_employees: 363,
    }

    single_value_field :status,
                       selector: '.d-md-inline-block > a:nth-child(3)',
                       when_defunct: Recorder::Entities::CovidStat::STATUS_UNKNOWN,
                       when_missing: Recorder::Entities::CovidStat::STATUS_UNKNOWN

    single_value_field :last_updated_at,
                       selector: '.large',
                       debug_name: 'update time',
                       when_defunct: use_defunct_date

    single_value_field :days_included,
                       selector: 'p.mb-1:nth-child(2)',
                       when_defunct: 'Past 14 Days',
                       when_missing: 'Past 14 Days'



    # This is for statistics caught by `#cleanse_for_css`
    MISSING_STATISTICS_TO_DEFAULTS = {
      quarantined_on_campus: -1,
      quarantined_off_campus: -1,
      isolated_on_campus: -1,
      isolated_off_campus: -1,
      tests_to_date: -1,
      isolation_bed_availability: -1,
      surveillance_positive_ratio: -1,
    }.transform_values(&:to_s).freeze

    def do_parse
      statistics = cleanse_for_css('.statistic > p:nth-child(1)')

      statistics.concat(MISSING_STATISTICS_TO_DEFAULTS.values)

      # Bring hospitalizations from front to end
      statistics.rotate!(1)

      statistics = sanitize(statistics)

      last_updated_at.squish!.gsub!(/^.+? updated: (.+?)\..*$/, '\1')
      days_included.gsub!(/(^|\S)\s+(\S|$)/, '\1 \2').gsub!(/^.*Past (\d+) Days.*$/i, '\1')

      statistics.merge!(
        campus_status: status || '',
        last_updated_at: last_updated_at,
        num_days_included: Integer(days_included)
      ).merge!(
        **LAST_TOTALS_FALL
      ) { |_k, old, new| old + new }
    end
  end
end
