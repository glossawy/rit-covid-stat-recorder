module Recorder::Spiders
  class RitSpiderFall2020 < RitSpiderBase
    self.dashboard_url = 'https://www.rit.edu/ready/fall-2020-dashboard'
    self.defunct_as_of = Date.parse('January 25, 2020')

    single_value_field :status,
                       selector: '.statistic > p:nth-child(1)',
                       when_defunct: Recorder::Entities::CovidStat::STATUS_UNKNOWN

    single_value_field :last_updated_at,
                       selector: '.large',
                       debug_name: 'update time',
                       when_defunct: use_defunct_date

    single_value_field :days_included,
                       selector: '.single-column-container-12163 > div:nth-child(2) > div:nth-child(1) > div:nth-child(2) > div:nth-child(1) > div:nth-child(1) > div:nth-child(1) > div:nth-child(1) > p:nth-child(2)',
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
      )
    end
  end
end
