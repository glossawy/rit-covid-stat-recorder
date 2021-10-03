module Recorder::Entities
  class CovidStat < Hanami::Entity
    delegate :attempted_at, to: :collection_attempt, allow_nil: true

    STATUS_UNKNOWN = 'Defunct/Unknown'.freeze

    def collection_attempt
      ca = super

      CollectionAttempt.new(ca) if ca
    end

    def recorded_at
      super || attempted_at
    end
  end
end
