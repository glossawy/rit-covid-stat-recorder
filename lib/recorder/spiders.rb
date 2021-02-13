module Recorder
  module Spiders
    require 'kimurai'

    require 'recorder/spiders/rit_spider_base'
    require 'recorder/spiders/rit_spider_fall2020'
    require 'recorder/spiders/rit_spider_spring2021'

    CURRENT = :spring
    NAMES_TO_SPIDERS = {
      fall: RitSpiderFall2020,
      spring: RitSpiderSpring2021,
    }

    %i[
      fall2020
      fall_spider
    ].each { |n| NAMES_TO_SPIDERS[n] = NAMES_TO_SPIDERS[:fall] }

    %i[
      spring2021
      spring_spider
    ].each { |n| NAMES_TO_SPIDERS[n] = NAMES_TO_SPIDERS[:spring] }

    NAMES_TO_SPIDERS[:current] = NAMES_TO_SPIDERS[CURRENT]

    NAMES_TO_SPIDERS.values.uniq.each(&:initialize!)
  end
end
