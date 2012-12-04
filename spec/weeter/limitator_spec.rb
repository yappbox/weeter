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

  describe '#limit_status' do

    subject do
      limitator.process(*keys)
    end

    context 'max: 0' do
      let(:max) { 0 }
      its(:status) { should == Weeter::Limitator::INITIATE_LIMITING }
      its(:limited_keys) { should == keys }

      context 'no keys' do
        let(:keys) { [] }
        its(:status) { should == Weeter::Limitator::DO_NOT_LIMIT }
        its(:limited_keys) { should == nil }
      end

      context 'two keys' do
        let(:keys) { ['key', 'key2'] }
        its(:status) { should == Weeter::Limitator::INITIATE_LIMITING }
        its(:limited_keys) { should == keys }
      end
    end

    context 'max: 1' do
      let(:max) { 1 }

      its(:status) { should == Weeter::Limitator::DO_NOT_LIMIT }
      its(:limited_keys) { should == nil }

      context 'two keys within max' do
        let(:keys) { ['key', 'key2'] }

        its(:status) { should == Weeter::Limitator::DO_NOT_LIMIT }
      end

      context 'no keys' do
        let(:keys) { [] }
        its(:status) { should == Weeter::Limitator::DO_NOT_LIMIT }
        its(:limited_keys) { should == nil }
      end

      context 'one key just outside max' do
        before do
          max.times do
            limitator.process(*keys)
          end
        end

        its(:status) { should == Weeter::Limitator::INITIATE_LIMITING }
        its(:limited_keys) { should == keys }

        context 'outside duration' do
          let(:some_time_after_duration) do
            Time.now + duration
          end

          before do
            limitator.stub(:now).and_return(some_time_after_duration)
          end

          its(:status) { should == Weeter::Limitator::DO_NOT_LIMIT }
          its(:limited_keys) { should == nil }
        end
      end

      context 'two keys just past max' do
        let(:keys) { ['key', 'key2'] }

        before do
          limitator.process(*keys)
        end

        its(:status) { should == Weeter::Limitator::INITIATE_LIMITING }
        its(:limited_keys) { should == keys }
      end

      context 'two keys past max' do
        let(:keys) { ['key', 'key2'] }

        before do
          limitator.process(*keys)
          limitator.process(*keys)
        end

        its(:status) { should == Weeter::Limitator::CONTINUE_LIMITING }
        its(:limited_keys) { should == keys }
      end

      context 'one key just past max: 1, one key within max: 1' do
        let(:max) { 1 }
        let(:keys) { ['key', 'key2'] }

        before do
          limitator.process(keys.first)
        end

        its(:status) { should == Weeter::Limitator::INITIATE_LIMITING }
        its(:limited_keys) { should == [keys.first] }
      end

      context 'one key past max: 1, one key within max: 1' do
        let(:max) { 1 }
        let(:keys) { ['key', 'key2'] }

        before do
          limitator.process(keys.first)
          limitator.process(keys.first)
        end

        its(:status) { should == Weeter::Limitator::CONTINUE_LIMITING }
        its(:limited_keys) { should == [keys.first] }
      end

      context 'one key past max: 1, one key just past max: 1' do
        let(:max) { 1 }
        let(:keys) { ['key', 'key2'] }

        before do
          limitator.process(*[keys.first])
          limitator.process(*[keys.first, keys.last])
        end

        its(:status) { should == Weeter::Limitator::INITIATE_LIMITING }
        its(:limited_keys) { should == keys }
      end
    end
  end
end
