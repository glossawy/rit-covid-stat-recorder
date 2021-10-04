module Recorder::Spiders
  class RitSpiderFall2021 < RitSpiderBase
    self.dashboard_url = 'https://www.rit.edu/ready/fall-2021-dashboard'

    LAST_TOTALS_SPRING = {
      total_cases_students: 379,
      total_cases_employees: 192,
    }

    single_value_field :status,
                       selector: '.d-md-inline-block > a:nth-child(3)',
                       when_defunct: Recorder::Entities::CovidStat::STATUS_UNKNOWN

    single_value_field :last_updated_at,
                       selector: '.large',
                       debug_name: 'update time',
                       when_defunct: use_defunct_date

    single_value_field :days_included,
                       selector: 'p.mb-1:nth-child(2)',
                       when_defunct: 'Past 14 Days'

    MISSING_STATISTICS_TO_DEFAULTS = {
      quarantined_on_campus: -1,
      quarantined_off_campus: -1,
      isolated_on_campus: -1,
      isolated_off_campus: -1,
      tests_to_date: -1,
      isolation_bed_availability: -1,
      surveillance_positive_ratio: -1,
    }.transform_values(&:to_s).freeze

    def status
      Recorder::Entities::CovidStat::STATUS_UNKNOWN
    end

    def do_parse
      statistics = cleanse_for_css('.statistic > p:nth-child(1)')

      statistics.concat(MISSING_STATISTICS_TO_DEFAULTS.values)

      statistics = sanitize(statistics)

      last_updated_at.squish!.gsub!(/^.+? updated: (.+?)\..*$/, '\1')
      days_included.gsub!(/(^|\S)\s+(\S|$)/, '\1 \2').gsub!(/^.*Past (\d+) Days.*$/i, '\1')

      statistics.merge!(
        campus_status: status || '',
        last_updated_at: last_updated_at,
        num_days_included: Integer(days_included)
      ).merge!(
        **LAST_TOTALS_SPRING
      ) { |_k, old, new| old + new }
    end
  end
end
