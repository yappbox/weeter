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
    it { limitator.should be }
  end

  describe '#limit?' do

    subject do
      limitator.limit?(*keys)
    end

    context 'max: 0' do
      let(:max) { 0 }
      it { should be_true }

      context 'no keys' do
        let(:keys) { [] }
        it { should be_false }
      end
    end

    context 'max: 1' do
      let(:max) { 1 }

      it { should be_false }

      context 'two keys within max' do
        let(:keys) { ['key', 'key2'] }

        it { should be_false }
      end

      context 'no keys' do
        let(:keys) { [] }
        it { should be_false }
      end

      context 'one key outside max' do
        before do
          max.times do
            limitator.limit?(*keys)
          end
        end

        it { should be_true }

        context 'outside duration' do
          let(:some_time_after_duration) do
            Time.now + duration
          end

          before do
            limitator.stub(:now).and_return(some_time_after_duration)
          end

          it { should be_false }
        end
      end

      context 'two keys outside' do
        let(:keys) { ['key', 'key2'] }

        before do
          limitator.limit?(*keys)
        end

        it { should be_true }
      end

      context 'one key outside max: 1, one key within max: 1' do
        let(:max) { 1 }
        let(:keys) { ['key', 'key2'] }

        before do
          limitator.limit?(*[keys.first])
        end

        it { should be_true }
      end
    end
  end
end

