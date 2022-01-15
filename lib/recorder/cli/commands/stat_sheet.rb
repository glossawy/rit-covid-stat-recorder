module Recorder
  class CLI
    module Commands
      class StatSheet
        attr_reader :svc

        COLUMN_TO_ATTR = {}
        COLUMN_TO_TRANSFORMS = {}
        HUMANIZERS = {}

        class << self
          private

          def convert_to_sheets_letter(i)
            q, r = i.divmod 26

            # Construct column letter right-to-left
            # A, B, C, ..., Z, AA, AB, AC,..., ZY, ZZ, AAA, AAB, ...
            prefix = q > 0 ? convert_to_sheets_letter(q - 1) : ''
            letter = ('A'.ord + r).chr

            prefix + letter
          end

          def letter_enum
            @letter_num ||=
              begin
                counter = 0
                Fiber.new do
                  loop do
                    Fiber.yield convert_to_sheets_letter(counter)
                    counter += 1
                  end
                end
              end
          end

          def define_column(letter = nil, attribute:, transform:, humanizer: nil)
            letter = letter_enum.resume while letter.nil? || letter.in?(COLUMN_TO_ATTR.keys)

            COLUMN_TO_ATTR[letter] = attribute
            COLUMN_TO_TRANSFORMS[letter] = transform.to_proc
            HUMANIZERS[letter] = humanizer.to_proc unless humanizer.nil?
            nil
          end

          def define_columns(attributes:, transform:, humanizer: nil)
            attributes.each { |attr| define_column(attribute: attr, transform: transform, humanizer: humanizer) }
          end
        end

        define_column attribute: :recorded_at,
                      transform: ->(x) { Time.parse_or_not(x).localtime },
                      humanizer: ->(x) { x.localtime.to_formatted_s(:rfc822) }

        define_column attribute: :last_updated_at,
                      transform: ->(x) { Time.parse_or_not(x) },
                      humanizer: ->(x) { x.to_date.to_s }

        define_column attribute: :campus_status,
                      transform: :itself

        define_columns transform: :to_i,
                       attributes: %i[
                         new_cases_students
                         new_cases_employees
                         num_days_included
                         total_cases_students
                         total_cases_employees
                         quarantined_on_campus
                         quarantined_off_campus
                         isolated_on_campus
                         isolated_off_campus
                         tests_to_date
                         isolation_bed_availability
                         surveillance_positive_ratio
                         hospitalizations
                       ]

        COLUMN_TO_ATTR.freeze
        COLUMN_TO_TRANSFORMS.freeze
        HUMANIZERS.freeze

        COLUMN_LETTERS = COLUMN_TO_ATTR.keys.freeze
        ATTR_TO_COLUMN = COLUMN_TO_ATTR.to_a.map(&:reverse).to_h.freeze
        PAGE_SIZE = 50

        def initialize
          @svc = Recorder.sheets_api

          Recorder.logger.info "Google Sheet ID  : #{sheet_id}"

          if sheet_name
            Recorder.logger.info "Google Sheet Name: #{sheet_name}"
          else
            Recorder.logger.warn \
              "No GOOGLE_SHEET_NAME defined, ranges will not be prefixed and may be wrong on multi-sheet spreadsheets!"
          end
        end

        def latest_entry
          recorded_stats.last
        end

        def append(stat, *stats)
          stats = [stat, *stats].sort_by(&:last_updated_at)
          values = stats.map { |s| map_stat_to_row(s) }

          response = svc.append_spreadsheet_value(*append_req(values))

          recorded_stats.concat(stats)

          OpenStruct.new(
            updated_table: response.table_range,
            updated_rows: response.updates.updated_rows,
            updated_range: response.updates.updated_range,
          )
        end

        def sheet_id
          ENV.fetch('GOOGLE_SHEET_ID')
        rescue KeyError
          raise KeyError, "GOOGLE_SHEET_ID environment variable is not defined"
        end

        def recorded_stats
          @recorded_stats ||= fetch_recorded_stats.map(&method(:map_row_to_stat))
        end

        private

        def range(from, to)
          "#{range_prefix}#{from}:#{to}"
        end

        def range_prefix
          if sheet_name.present?
            "#{sheet_name}!"
          else
            (@warning_missing_sheet_name = true and puts 'No sheet name provided! Ranges may be wrong.') unless @warning_missing_sheet_name
            ''
          end
        end

        def sheet_name
          ENV['GOOGLE_SHEET_NAME']
        end

        def ordered_attr_names
          @ordered_attr_names||= COLUMN_TO_ATTR.to_a.sort_by(&:first).map(&:second)
        end

        def ordered_transforms
          @ordered_transforms ||= COLUMN_TO_TRANSFORMS.to_a.sort_by(&:first).map(&:second)
        end

        def ordered_humanizers
          @ordered_humanizers ||= COLUMN_TO_TRANSFORMS.merge(HUMANIZERS).to_a.sort_by(&:first).map(&:second)
        end

        def map_row_to_hash(row)
          ordered_attr_names.zip(ordered_transforms, row).each_with_object({}) do |(name, fn, val), hsh|
            hsh[name] = fn[val]
          end
        rescue
          binding.pry
          raise
        end

        def map_row_to_stat(row)
          Entities::CovidStat.new(map_row_to_hash(row))
        end

        def map_stat_to_row(statistic)
          ordered_attr_names.zip(ordered_humanizers).map do |attr, fn|
            fn.call(statistic.public_send(attr)).to_s
          end
        end

        def fetch_recorded_stats(offset=0, page_size = PAGE_SIZE)
          r = range("A#{3 + offset}", "#{COLUMN_LETTERS.last}#{3 + offset + page_size - 1}")
          result = svc.get_spreadsheet_values(sheet_id, r)
          values = result&.values

          return [] unless values.present?

          values.tap do
            values.concat fetch_recorded_stats(offset + page_size, page_size) if values.size == page_size
          end
        end

        def append_req(values)
          [
            sheet_id,
            range('A3', "#{COLUMN_LETTERS.last}3"),
            ::Google::Apis::SheetsV4::ValueRange.new(values: values),
            {
              value_input_option: 'USER_ENTERED',
            },
          ]
        end
      end
    end
  end
end
