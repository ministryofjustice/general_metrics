RSpec.describe MetricsAdapter::Trackers::SlowRequest do
  subject(:slow_request) { described_class.new(event) }

  describe '#call' do
    before do
      allow(
        ::MetricsAdapter
      ).to receive(:thresholds).and_return(slow_request: 100)

      allow(
        ::MetricsAdapter
      ).to receive(:adapter).and_return(:mixpanel)

      allow(
        ::MetricsAdapter
      ).to receive(:adapter_options).and_return(secret: 'foo')
    end

    context 'when event duration is less than the slow request threshold' do
      let(:event) do
        double(duration: 1)
      end

      it 'do not send any metrics' do
        expect(slow_request.adapter).to_not receive(:publish)
        slow_request.call
      end
    end

    context 'when event duration is greater than the slow request threshold' do
      let(:event) do
        double(
          duration: 1100,
          transaction_id: '111',
          idle_time: 1099,
          cpu_time: 1,
          payload: { method: 'GET', path: '/' }
        )
      end

      it 'sends metrics' do
        expect(slow_request.adapter).to receive(:publish)
        slow_request.call
      end
    end

    context 'when metrics condition is false' do
      let(:event) do
        double(duration: 100_000)
      end

      before do
        allow(
          ::MetricsAdapter
        ).to receive(:conditionals).and_return(slow_request: -> { false })
      end

      it 'do not send any metrics' do
        expect(slow_request.adapter).to_not receive(:publish)
        slow_request.call
      end
    end

    context 'when metrics condition is true' do
      let(:event) do
        double(
          duration: 1100,
          transaction_id: '111',
          idle_time: 1099,
          cpu_time: 1,
          payload: { method: 'GET', path: '/' }
        )
      end

      before do
        allow(
          ::MetricsAdapter
        ).to receive(:conditionals).and_return(slow_request: -> { true })
      end

      it 'sends metrics' do
        expect(slow_request.adapter).to receive(:publish)
        slow_request.call
      end
    end
  end
end
