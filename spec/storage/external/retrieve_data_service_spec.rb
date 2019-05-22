require './spec/spec_helper'

describe Storage::External::RetrieveDataService do
  describe '#call' do
    let(:url) { 'http://some.external.endpoint' }
    let(:logger_stub) { double('MainLogger', error: true) }

    let(:faraday) { service.send(:connection) }
    let(:service) { described_class.new(url: url) }

    subject { service.call }

    context 'when external service returns error' do
      let(:error_message) { 'Some error' }

      before do
        allow(faraday).to receive(:get).and_raise(StandardError, error_message)
      end

      it 'calls Faraday with url' do
        expect(faraday).to receive(:get).with(url)

        subject
      end

      it 'does not parse anything' do
        expect(JSON).to_not receive(:parse)

        subject
      end

      it 'logs error' do
        expect(MainLogger).to receive(:error).with(error_message)

        subject
      end

      it { is_expected.to be_nil }
    end

    context 'when external service is successful' do
      let(:response_body) do
        {
          ads: []
        }
      end

      let(:json_response_body) { response_body.to_json }

      before do
        allow(faraday).to receive(:get) { double('Response', body: json_response_body, success?: true) }
      end

      it 'calls Faraday with url' do
        expect(faraday).to receive(:get).with(url)

        subject
      end

      it 'parses body' do
        expect(JSON).to receive(:parse).with(json_response_body, symbolize_names: true)

        subject
      end

      it do
        is_expected.to eq(response_body)
      end
    end
  end
end
