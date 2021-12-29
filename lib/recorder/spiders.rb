module Recorder
  module Spiders
    require 'kimurai'

    require_relative './spiders/rit_spider_base'
    require_relative './spiders/rit_spider_fall2020'
    require_relative './spiders/rit_spider_spring2021'
    require_relative './spiders/rit_spider_fall2021'
    require_relative './spiders/rit_spider_spring2022'

    CURRENT = :spring2022
    NAMES_TO_SPIDERS = {
      fall2020: RitSpiderFall2020,
      spring2021: RitSpiderSpring2021,
      fall2021: RitSpiderFall2021,
      spring2022: RitSpiderSpring2022,
    }

    %i[
      spring
      spring_spider
    ].each { |n| NAMES_TO_SPIDERS[n] = NAMES_TO_SPIDERS[:spring2022] }

    %i[
      fall
      fall_spider
    ].each { |n| NAMES_TO_SPIDERS[n] = NAMES_TO_SPIDERS[:fall2021] }

    NAMES_TO_SPIDERS[:current] = NAMES_TO_SPIDERS[CURRENT]

    NAMES_TO_SPIDERS.values.uniq.each(&:initialize!)
  end
end
