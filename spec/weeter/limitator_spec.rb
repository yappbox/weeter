require 'spec_helper'

describe Weeter::Limitator do
  let(:limitator) do
    Weeter::Limitator.new({
      max: max,
      duration: duration
    })
  end

  let(:duration) { 10.minutes }
  let(:max) { 10 }

  let(:keys) { ['key'] }

  describe '.new' do
    it { expect(limitator).to be }
  end

  describe '#limit_status' do

    subject do
      limitator.process(*keys)
    end

    context 'max: 0' do
      let(:max) { 0 }
      it { expect(subject.status).to eq(Weeter::Limitator::INITIATE_LIMITING) }
      it { expect(subject.limited_keys).to eq(keys) }

      context 'no keys' do
        let(:keys) { [] }
        it { expect(subject.status).to eq(Weeter::Limitator::DO_NOT_LIMIT) }
        it { expect(subject.limited_keys).to be_nil }
      end

      context 'two keys' do
        let(:keys) { ['key', 'key2'] }
        it { expect(subject.status).to eq(Weeter::Limitator::INITIATE_LIMITING) }
        it { expect(subject.limited_keys).to eq(keys) }
      end
    end

    context 'max: 1' do
      let(:max) { 1 }

      it { expect(subject.status).to eq(Weeter::Limitator::DO_NOT_LIMIT) }
      it { expect(subject.limited_keys).to be_nil }

      context 'two keys within max' do
        let(:keys) { ['key', 'key2'] }

        it { expect(subject.status).to eq(Weeter::Limitator::DO_NOT_LIMIT) }
      end

      context 'no keys' do
        let(:keys) { [] }
        it { expect(subject.status).to eq(Weeter::Limitator::DO_NOT_LIMIT) }
        it { expect(subject.limited_keys).to be_nil }
      end

      context 'one key just outside max' do
        before do
          max.times do
            limitator.process(*keys)
          end
        end

        it { expect(subject.status).to eq(Weeter::Limitator::INITIATE_LIMITING) }
        it { expect(subject.limited_keys).to eq(keys) }

        context 'outside duration' do
          let(:some_time_after_duration) do
            Time.now + duration
          end

          before do
            expect(limitator).to receive(:now).and_return(some_time_after_duration).at_least(:once)
          end

          it { expect(subject.status).to eq(Weeter::Limitator::DO_NOT_LIMIT) }
          it { expect(subject.limited_keys).to be_nil }
        end
      end

      context 'two keys just past max' do
        let(:keys) { ['key', 'key2'] }

        before do
          limitator.process(*keys)
        end

        it { expect(subject.status).to eq(Weeter::Limitator::INITIATE_LIMITING) }
        it { expect(subject.limited_keys).to eq(keys) }
      end

      context 'two keys past max' do
        let(:keys) { ['key', 'key2'] }

        before do
          limitator.process(*keys)
          limitator.process(*keys)
        end

        it { expect(subject.status).to eq(Weeter::Limitator::CONTINUE_LIMITING) }
        it { expect(subject.limited_keys).to eq(keys) }
      end

      context 'one key just past max: 1, one key within max: 1' do
        let(:max) { 1 }
        let(:keys) { ['key', 'key2'] }

        before do
          limitator.process(keys.first)
        end

        it { expect(subject.status).to eq(Weeter::Limitator::INITIATE_LIMITING) }
        it { expect(subject.limited_keys).to eq([keys.first]) }
      end

      context 'one key past max: 1, one key within max: 1' do
        let(:max) { 1 }
        let(:keys) { ['key', 'key2'] }

        before do
          limitator.process(keys.first)
          limitator.process(keys.first)
        end

        it { expect(subject.status).to eq(Weeter::Limitator::CONTINUE_LIMITING) }
        it { expect(subject.limited_keys).to eq([keys.first]) }
      end

      context 'one key past max: 1, one key just past max: 1' do
        let(:max) { 1 }
        let(:keys) { ['key', 'key2'] }

        before do
          limitator.process(*[keys.first])
          limitator.process(*[keys.first, keys.last])
        end

        it { expect(subject.status).to eq(Weeter::Limitator::INITIATE_LIMITING) }
        it { expect(subject.limited_keys).to eq(keys) }
      end
    end
  end
end
