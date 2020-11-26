module Recorder::Repositories
  module Namespaced
    class RelationName < Hanami::Model::RelationName; end
    
    class EntityName < Hanami::Model::EntityName
      def underscore
        @name.demodulize.underscore.to_sym
      end
    end

    def self.included(base)
      require 'hanami/model/entity_name'
      require 'hanami/model/relation_name'
      
      repo_name = base.name.demodulize
      entity_name = base.name.sub(/::Repositories::/, '::Entities::')
      base.entity_name = EntityName.new(entity_name)
      base.relation = RelationName.new(repo_name)
    end
  end
end
