module Recorder::Spiders
  class RitSpiderBase < Kimurai::Base
    DEFAULT_CONFIG = { user_agent: 'Mozilla/5.0 Gecko/20100101 Firefox/80.0' }.freeze

    class_attribute :academic_term
    class_attribute :engine, default: :mechanize
    class_attribute :defunct_as_of
    class_attribute :dashboard_url
    class_attribute :config, default: DEFAULT_CONFIG

    @name = 'rit_covid_spider'
    @engine = :mechanize
    @start_urls = ['https://www.rit.edu/ready/dashboard']
    @config = {
      user_agent: 'Mozilla/5.0 Gecko/20100101 Firefox/80.0'
    }

    def self.single_value_fields
      @single_value_fields ||= []
    end

    def self.initialize!
      unless @initialized
        raise 'Missing dashboard url class attribute' unless dashboard_url

        @name = to_s.demodulize.underscore

        if self.academic_term
          @name = "rit_dashboard_spider_#{academic_term.underscore}"
        end

        @engine = engine
        @start_urls = [dashboard_url]
        @config = config

        @initialized = true
      end
    end

    def self.use_defunct_date
      proc do
        defunct_as_of.to_formatted_s(:long)
      end
    end

    def self.single_value_field(field_name, selector:, when_defunct:, when_missing: nil, debug_name: nil)
      debug_name ||= field_name.to_s.tr('_', ' ')
      field_find_name ||= "find_#{field_name}_in_response"

      when_defunct = Recorder::ProcOrValue.new(when_defunct)
      when_missing = Recorder::ProcOrValue.new(when_missing)

      define_method(field_find_name) do
        if defunct?
          when_defunct.call_or_get
        elsif response
          first_cleansed_for_css(selector, debug_name: debug_name).presence || when_missing.call_or_get
        end.tap do |x|
          logger.debug("Found value for #{debug_name} (#{field_name}): << #{x} >>")
        end
      end
      private(field_find_name)

      class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
        def #{field_name}
          @#{field_name} ||= #{field_find_name}
        end
      RUBY

      single_value_fields << field_name
    end

    attr_reader :stat_repo, :logger, :response

    def initialize
      self.class.initialize!
      super

      @logger = Recorder.logger
      @stat_repo = Recorder::Repositories::CovidStatRepository.new
    end

    def parse(response, url:, data: {})
      @response = response
      do_parse
    end

    private

    def cleanse_for_css(css_selector)
      response.css(css_selector).map(&method(:cleanse))
    end

    def first_cleansed_for_css(css_selector, debug_name: 'item', &block)
      block ||= default_for_first_with_warn(debug_name)
      get_first_with_warn(cleanse_for_css(css_selector), &block)
    end

    define_method :cleanse, &(%i[strip text].map(&:to_proc).reduce { |a, e|  a << e })

    def default_for_first_with_warn(debug_name)
      proc do |items, type, fmt|
        case type
        when :too_many
          [fmt["More than one #{debug_name}, found %<size>d: %<items>s"], items.first]
        when :empty
          [fmt["#{debug_name.to_s.titleize} not found in page"], nil]
        else
          [fmt["Invalid #{debug_name}"], nil]
        end
      end
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

    def sanitize(statistics)
      statistics = statistics.map(&:strip)

      nc_s, nc_e, tc_s, tc_e, q_on, q_off, i_on, i_off, tests_to_date, bed_pct, surv_pos_pct, *rest = statistics
      if defunct?
        tc_s, tc_e, q_on, q_off, i_on, i_off, tests_to_date, bed_pct, surv_pos_pct, *rest = statistics

        # Not available when dashboard is replaced, so reuse prior values
        stat = stat_repo.most_recent
        nc_s = stat&.new_cases_students || -1
        nc_e = stat&.new_cases_employees || -1
      end

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

    def defunct?
      defunct_date.present?
    end

    def defunct_date
      self.class.defunct_as_of
    end
  end
end
