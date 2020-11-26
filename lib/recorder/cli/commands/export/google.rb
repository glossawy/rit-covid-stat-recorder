module Recorder
  class CLI
    module Commands
      module Export
        class Google < Command
          desc 'Sync latest data to google sheets'

          def call(**options)
            context = Context.new(options: options)

            sync_to_google_sheets(context)
          end

          private

          def log(*args)
            Recorder.logger.info(*args) unless args.empty?
          end

          def sync_to_google_sheets(_context)
            if updates.empty?
              log "No updates to sync."
              log
            else
              stats_sheet.append(*updates).tap do |response|
                log ''
                log "  Successfully sync'd with google sheets."
                log "    Table Range : #{response.updated_table}"
                log "    Update Range: #{response.updated_range}"
                log "    Updated Rows: #{response.updated_rows}"
                log ''
              end
            end
          end

          def updates
            @updates ||= covid_stat_repo.relevant_updates(reference_stat)
          end

          def reference_stat
            @reference_stat ||= covid_stat_repo.fuzzy_find_with_attempt(stats_sheet.latest_entry)
          end
        end
      end
    end
  end
end
