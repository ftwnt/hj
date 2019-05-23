require './lib/base/keyword'
require './lib/main_logger'
require './lib/storage/external/retrieve_data_service'
require './lib/storage/internal/retrieve_data_service'

class ComparisonService < Base::Keyword
  ATTRIBUTES_MAPPING = {
    external_reference: :reference,
    ad_description: :description
  }

  COMPARED_ATTRIBUTES = [:status, :description]

  attr_reader :internal_source_type, :external_url, :result

  def initialize(internal_source_type:, external_url:)
    @internal_source_type = internal_source_type
    @external_url = external_url
  end

  def call
    return [] if any_blank_data?

    compare(adapted_internal_data, external_data)
  rescue => e
    message = [service_exception_message, e.message].join(': ')

    handle_exception(message)
  end

  private

  def internal_data
    @internal_data ||= Storage::Internal::RetrieveDataService.call(source_type: internal_source_type)
  end

  def external_data
    @external_data ||= Storage::External::RetrieveDataService.call(url: external_url)

    return if external_data_empty?

    @external_data[:ads]
  end

  def external_data_empty?
    @external_data.nil? || @external_data.empty?
  end

  def any_blank_data?
    [internal_data, external_data].any? { |data| data.nil? || data.empty? }
  end

  def service_exception_message
    'Could not perform comparison'
  end

  # Transform internal data to external view by keys
  def adapted_internal_data
    internal_data.map do |data|
      data.transform_keys { |k| ATTRIBUTES_MAPPING[k] || k }
    end
  end

  def compare(internal, external)
    @result = []

    external.each do |remote|
      reference = remote[:reference]
      local = internal.find { |int_record| int_record[:reference].to_i == reference.to_i }

      if local.nil?
        result << local_not_found(reference)

        next
      end

      # Bring +local+ and +remote+ records to the general view
      # and compare them by arrays.
      m_local, m_remote = [local, remote].map do |record|
        record.slice(*COMPARED_ATTRIBUTES).to_a
      end

      result << difference(local, remote) if m_remote != (m_local & m_remote)
    end

    result
  end

  def local_not_found(remote_reference)
    {
      remote_reference: remote_reference,
      discrepancies: 'Not found'
    }
  end

  def difference(local, remote)
    obj = { remote_reference: remote[:reference], discrepancies: [] }

    obj[:discrepancies] << COMPARED_ATTRIBUTES.map do |attribute|
      next if remote[attribute] == local[attribute]

      [
        attribute,
        {
          remote: remote[attribute],
          local: local[attribute]
        }
      ]
    end.compact.to_h

    obj
  end

  def handle_exception(message)
    MainLogger.warn(message)

    false
  end
end
