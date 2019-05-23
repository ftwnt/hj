require 'spec_helper'

describe ComparisonService do
  let(:internal_service) { Storage::Internal::RetrieveDataService }
  let(:external_service) { Storage::External::RetrieveDataService }
  let(:url) { 'http://some.url' }

  subject { described_class.call(internal_source_type: source_type, external_url: url) }

  context 'when source_type is invalid' do
    let(:source_type) { nil }
    let(:exception_message) { 'Some exception' }

    before { allow(internal_service).to receive(:call).and_raise(StandardError, exception_message) }

    it 'tries to call internal data retrieval service' do
      expect(internal_service).to receive(:call).with(source_type: source_type)

      subject
    end

    it 'does not call external data retrieval service' do
      expect(external_service).to_not receive(:call).with(url: url)

      subject
    end

    it 'writes message to logger' do
      expect(MainLogger).to receive(:warn).with("Could not perform comparison: #{exception_message}")

      subject
    end
  end

  context 'when source_type is valid' do
    let(:source_type) { Storage::Internal::RetrieveDataService::ALLOWED_SOURCE_TYPES.sample }

    before { allow(external_service).to receive(:call) { {} } }

    it 'calls internal data retrieval service' do
      expect(internal_service).to receive(:call).with(source_type: source_type)

      subject
    end

    it 'calls external data retrieval service' do
      expect(external_service).to receive(:call).with(url: url)

      subject
    end

    context 'and external service returns nothing' do
      let(:expected_result) { [] }

      it { is_expected.to eq(expected_result) }
    end

    context 'and external service returns valid data' do
      before do
        allow(internal_service).to receive(:call) { internal_service_result }
        allow(external_service).to receive(:call) { external_service_result }
      end

      context 'and remote reference could not be found in internal data' do
        let(:internal_service_result) do
          [
            {
              id: 1,
              job_id: 1,
              status: 'active',
              external_reference: 1,
              ad_description: 'Description for campaign 12'
            }
          ]
        end

        let(:external_service_result) do
          {
            "ads": [
              {
                "reference": "2",
                "status": "disabled",
                "description": "Description for campaign 12"
              }
            ]
          }
        end

        let(:expected_result) do
          [
            {
              "remote_reference": "2",
              "discrepancies": "Not found"
            }
          ]
        end

        it { is_expected.to eq(expected_result) }
      end

      context 'and remote reference could be found in internal data' do
        context 'and difference exists' do
          let(:internal_service_result) do
            [
              {
                id: 1,
                job_id: 1,
                status: 'active',
                external_reference: 2,
                ad_description: 'Ruby on Rails Developer'
              }
            ]
          end

          let(:external_service_result) do
            {
              "ads": [
                {
                  "reference": "2",
                  "status": "disabled",
                  "description": "Rails Engineer"
                }
              ]
            }
          end

          let(:expected_result) do
            [
              {
                "remote_reference": "2",
                "discrepancies": [
                  "status": {
                    "remote": "disabled",
                    "local": "active"
                  },
                  "description": {
                    "remote": "Rails Engineer",
                    "local": "Ruby on Rails Developer"
                  }
                ]
              }
            ]
          end

          it do
            is_expected.to eq(expected_result)
          end
        end

        context 'and no difference exists' do
          let(:internal_service_result) do
            [
              {
                id: 1,
                job_id: 1,
                status: 'disabled',
                external_reference: 2,
                ad_description: 'Description for campaign 12'
              }
            ]
          end

          let(:external_service_result) do
            {
              "ads": [
                {
                  "reference": "2",
                  "status": "disabled",
                  "description": "Description for campaign 12"
                }
              ]
            }
          end

          let(:expected_result) { [] }

          it { is_expected.to eq(expected_result) }
        end
      end
    end
  end
end
