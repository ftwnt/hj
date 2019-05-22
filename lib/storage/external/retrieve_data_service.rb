require 'faraday'
require 'json'

require './lib/base/keyword'
require './lib/main_logger'

module Storage
  module External
    class RetrieveDataService < Base::Keyword
      attr_reader :url, :data

      def initialize(url:)
        @url = url
      end

      def call
        response = connection.get(url)

        return unless response.success?

        @data = JSON.parse(response.body, symbolize_names: true)
      rescue => e
        MainLogger.error(e.message)

        nil
      end

      private

      def connection
        @connection ||= Faraday.new
      end
    end
  end
end
