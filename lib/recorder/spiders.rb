module Recorder
  module Spiders
    require 'kimurai'

    require 'recorder/spiders/rit_spider_base'
    require 'recorder/spiders/rit_spider_fall2020'
    require 'recorder/spiders/rit_spider_spring2021'
    require 'recorder/spiders/rit_spider_fall2021'

    CURRENT = :fall2021
    NAMES_TO_SPIDERS = {
      fall2020: RitSpiderFall2020,
      spring2021: RitSpiderSpring2021,
      fall2021: RitSpiderFall2021,
    }

    %i[
      spring
      spring_spider
    ].each { |n| NAMES_TO_SPIDERS[n] = NAMES_TO_SPIDERS[:spring2021] }

    %i[
      fall
      fall_spider
    ].each { |n| NAMES_TO_SPIDERS[n] = NAMES_TO_SPIDERS[:fall2021] }

    NAMES_TO_SPIDERS[:current] = NAMES_TO_SPIDERS[CURRENT]

    NAMES_TO_SPIDERS.values.uniq.each(&:initialize!)
  end
end
