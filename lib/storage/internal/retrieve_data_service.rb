require './lib/base/keyword'
require_relative 'sources/json'

module Storage
  module Internal
    class RetrieveDataService < Base::Keyword
      ALLOWED_SOURCE_TYPES = %i[json]

      attr_reader :source_type

      def initialize(source_type:)
        @source_type = source_type
      end

      def call
        retrieval_service.call
      end

      private

      def retrieval_service
        raise ArgumentError, 'Unknown type of internal source' unless source_type_allowed?

        Object.const_get("Storage::Internal::Sources::#{source_class_name}")
      end

      def source_type_allowed?
        ALLOWED_SOURCE_TYPES.include?(source_type)
      end

      def source_class_name
        source_type.to_s.capitalize
      end
    end
  end
end
