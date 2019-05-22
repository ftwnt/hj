require './spec/spec_helper'
require './lib/storage/internal/retrieve_data_service'

describe Storage::Internal::RetrieveDataService do
  describe '#call' do
    subject { described_class.call(source_type: source_type) }

    context 'when allowed type passed' do
      context 'and is :json' do
        let(:source_type) { :json }

        it 'calls corresponding retrieval service' do
          expect(Storage::Internal::Sources::Json).to receive(:call)

          subject
        end
      end
    end

    context 'when incorrect type passed' do
      let(:logger_stub) { double('MainLogger', error: true) }
      let(:source_type) { :invalid }

      it 'raises error' do
        expect { subject }.to raise_error ArgumentError
      end
    end
  end
end
