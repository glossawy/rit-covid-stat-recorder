module Recorder::Repositories
  class CollectionAttemptRepository < Hanami::Repository
    include Namespaced

    associations do
      belongs_to :covid_stats
    end

    def log_failure(reason:, attempted_at:, note: nil)
      note ||= ''

      create(
        success: false,
        reason: reason,
        note: note,
        attempted_at: attempted_at
      )
    end

    def record_success(covid_stat, reason: nil, note: nil)
      reason ||= ''
      note ||= ''

      assoc(:covid_stat).create(
        success: true, 
        reason: reason, 
        note: note,
        attempted_at: covid_stat.recorded_at,
        covid_stat: covid_stat,
      )
    end
  end
end
