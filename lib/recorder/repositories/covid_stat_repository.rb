module Recorder::Repositories
  class CovidStatRepository < Hanami::Repository
    include Namespaced

    self.relation = :covid_stats

    associations do
      has_one :collection_attempt
    end

    def success(data, note: nil, reason: nil)
      transaction do
        assoc(:collection_attempt).create(
          **data,
          collection_attempt: {
            success: true,
            reason: reason || '',
            note: reason || '',
            attempted_at: data.recorded_at,
          },
        )
      end
    end

    def most_recent
      aggregate(:collection_attempt).reverse(:id).map_to(Recorder::Entities::CovidStat).first
    end

    def relevant_updates(reference_stat)
      aggregate(:collection_attempt)
        .join(:collection_attempts)
        .where(
          collection_attempts[:success].qualified \
          & (collection_attempts[:attempted_at] > reference_stat.recorded_at) \
          & (covid_stats[:last_updated_at] != reference_stat.last_updated_at)
        )
        .map_to(Recorder::Entities::CovidStat)
        .to_a
    end

    def with_attempts
      aggregate(:collection_attempt).map_to(Recorder::Entities::CovidStat).to_a
    end

    def fuzzy_find_with_attempt(reference)
      equivalent = %i[
        new_cases_students
        new_cases_employees
        quarantined_on_campus
        quarantined_off_campus
        isolated_on_campus
        isolated_off_campus
        isolation_bed_availability
        surveillance_positive_ratio
      ]

      equivalence = equivalent.map do |field|
        covid_stats[field] =~ reference.public_send(field)
      end.reduce { |a, e| a & e }

      reference_updated_at = reference.last_updated_at.utc
      aggregate(:collection_attempt).where(
        (covid_stats[:last_updated_at] =~ reference_updated_at) | (covid_stats[:last_updated_at] =~ reference_updated_at.to_date) \
        & equivalence
      ).map_to(Recorder::Entities::CovidStat).one
    end

    def find_with_attempt(id)
      aggregate(:collection_attempt).where(id: id).map_to(Recorder::Entities::CovidStat).one
    end
  end
end
