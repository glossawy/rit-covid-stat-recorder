module Recorder::Spiders
  class RitSpiderSpring2021 < RitSpiderBase
    self.dashboard_url = 'https://www.rit.edu/ready/spring-2021-dashboard'
    self.defunct_as_of = Date.parse('May 25, 2021')

    LAST_TOTALS_FALL = {
      total_cases_students: 221,
      total_cases_employees: 45,
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

    def do_parse
      statistics = cleanse_for_css('.statistic > p:nth-child(1)')
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
