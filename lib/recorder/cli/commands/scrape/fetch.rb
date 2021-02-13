module Recorder
  class CLI
    module Commands
      module Scrape
        class Fetch < Scrape::Command
          desc "Fetch and display today's covid stats"

          option :persist, type: :boolean, default: false, desc: 'Persist stats to db'
          option :notify, type: :boolean, default: false, desc: 'Toast notification when relvant statistic'
          option :spider, type: :string, default: Recorder::Spiders::CURRENT, desc: 'Which spider to use', values: Recorder::Spiders::NAMES_TO_SPIDERS.keys.map(&:to_s)

          def call(persist:, notify:, spider:, **options)
            @spider_name = spider
            context = Context.new(persist?: persist, notify?: notify, options: options)

            fetch_data(context)
          end

          private

          def fetch_data(context)
            result, s, e = record_time { scrape! }

            covid_stat = as_covid_stat(result, s, e)
            context = context.with(
              { 
                record_start_at: s, 
                record_end_at: e,
                statistic: covid_stat,
                new?: new_statistic?(covid_stat)
              }
            )

            display_result(context)
            notify_result!(context) if context.notify?
            persist_result!(context) if context.persist?
          end

          def persist_result!(context)
            context.logger.info 'Persisting statistic...'            

            cstat = context.statistic

            unless context.new?
              collection_attempt_repo.log_failure(
                reason: 'Found an existing statistic via fuzzy find',
                attempted_at: context.record_start_at
              )
              context.logger.info 'No statistic saved because an existing one was found.'
            else
              covid_stat_repo.success(cstat)
              context.logger.info 'Done!'
            end
          end

          def display_result(context)
            cstat = context.statistic
            start_time = context.record_start_at
            end_time = context.record_end_at
            
            fields = cstat.to_h.keys.sort
            padding = fields.map(&:size).max + 1
            
            info
            info "     Started Recording at: #{start_time.to_formatted_s(:rfc822)}"
            info "    Finished Recording at: #{end_time.to_formatted_s(:rfc822)}"
            info "Dashboard Last Updated at: #{rit_updated_at.to_formatted_s(:rfc822)}"
            info
            fields.each do |field|
              info("%<field>#{padding}s: %<value>s" % { field: field, value: cstat.send(field) })
            end
            info
          end

          def notify_result!(context)
            Recorder::Notifications.new_statistic! if context.new?
          end

          def as_covid_stat(result, start_time, end_time)
            Entities::CovidStat.new(
              result.merge(recorded_at: start_time, last_updated_at: Time.zone.parse(result[:last_updated_at]).to_date)
            )
          end

          def new_statistic?(cstat)
            !covid_stat_repo.fuzzy_find_with_attempt(cstat)
          end
        end
      end
    end
  end
end
