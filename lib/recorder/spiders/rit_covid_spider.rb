module Recorder::Spiders
  class RitCovidSpider < Kimurai::Base
    @name = 'rit_covid_spider'
    @engine = :mechanize
    @start_urls = ['https://www.rit.edu/ready/dashboard']
    @config = {
      user_agent: 'Mozilla/5.0 Gecko/20100101 Firefox/80.0'
    }

    attr_reader :repo, :logger

    def initialize
      super
      @logger = Recorder.logger
      @repo = Recorder::Repositories::CovidStatRepository.new
    end

    def parse(response, url:, data: {})
      cleanse = %i[
        strip
        text
      ].map(&:to_proc).reduce { |a, e| a << e }

      statistics = response.css('.statistic > p:nth-child(1)').map(&cleanse)
      statistics = sanitize(statistics)

      status = response.css('#pandemic-message-container a').map(&cleanse)
      last_updated_at = response.css('.large > strong:nth-child(2)').map(&cleanse)
      days_included = response.css('.single-column-container-12163 > div:nth-child(2) > div:nth-child(1) > div:nth-child(2) > div:nth-child(1) > div:nth-child(1) > div:nth-child(1) > div:nth-child(1) > p:nth-child(2)').map(&cleanse)

      status = get_first_with_warn(status) do |type, items, fmt|
        case type
        when :too_many
          [fmt['More than one status found, found %<size>d: %<items>s'], items.first]
        when :empty
          [fmt['No campus status found!'], nil]
        else
          [fmt['Issue with status result'], nil]
        end
      end

      last_updated_at = get_first_with_warn(last_updated_at) do |type, items, fmt|
        case type
        when :too_many
          [fmt['More than one update time, found %<size>d: %<items>s'], items.first]
        when :empty
          [fmt['Last updated at not found in page'], nil]
        else
          [fmt['Invalid last updated at'], nil]
        end
      end

      days_included = get_first_with_warn(days_included) do |type, items, fmt|
        case type
        when :too_many
          [fmt['More than one days included, found %<size>d: %<items>s'], items.first]
        when :empty
          [fmt['Day included not found in page'], nil]
        else
          [fmt['Invalid days included'], nil]
        end
      end

      days_included.gsub!(/(^|\S)\s+(\S|$)/, '\1 \2').gsub!(/^.*Past (\d+) Days.*$/i, '\1')

      statistics.merge!(
        campus_status: status || '',
        last_updated_at: last_updated_at,
        num_days_included: Integer(days_included)
      )
    end

    private

    def sanitize(statistics)
      nc_s, nc_e, tc_s, tc_e, q_on, q_off, i_on, i_off, tests_to_date, bed_pct, surv_pos_pct, *rest = statistics.map(&:strip)

      bed_pct = bed_pct.chomp('%')
      surv_pos_pct = surv_pos_pct.chomp('%')

      if rest.any?
        logger.warn(
          "More statistics than anticipated were found. " \
          "Found #{statistics.size} with #{rest.join(', ')} being extraneous."
        )
      end

      surv_pos_pct = -1 if surv_pos_pct =~ /^[a-z]/i
      tests_to_date.gsub!(/[^\d]/, '')

      {
        new_cases_students: nc_s,
        new_cases_employees: nc_e,
        total_cases_students: tc_s,
        total_cases_employees: tc_e,
        quarantined_on_campus: q_on,
        quarantined_off_campus: q_off,
        isolated_on_campus: i_on,
        isolated_off_campus: i_off,
        tests_to_date: tests_to_date,
        isolation_bed_availability: bed_pct,
        surveillance_positive_ratio: surv_pos_pct
      }.transform_values(&:to_i)
    end

    def get_first_with_warn(items)
      format_params = { items: items.join(', '), size: items.size }
      fmt = ->(m) { m % format_params }

      if items.size == 1
        items.first
      else
        msg, result =
          if items.empty?
            yield :empty, items, fmt
          elsif items.size > 1
            yield :too_many, items, fmt
          else
            yield :invalid, items, fmt
          end
        
        logger.warn(msg)
        result
      end
    end
  end
end
