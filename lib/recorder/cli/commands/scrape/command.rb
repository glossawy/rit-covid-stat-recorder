module Recorder
  class CLI
    module Commands
      module Scrape
        class Command < Commands::Command
          attr_reader :spider_name

          def scraper
            Recorder::Spiders::NAMES_TO_SPIDERS[spider_name&.to_sym || Recorder::Spiders::CURRENT]
          end

          def scrape!(url = nil)
            url ||= scraper.start_urls.first
            scraper.parse!(:parse, url: url)
          end

          def record_time
            start_time = Time.now
            result = yield start_time
            end_time = Time.now

            return result, start_time, end_time
          end
        end
      end
    end
  end
end
