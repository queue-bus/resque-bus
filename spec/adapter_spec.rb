require 'spec_helper'

describe "adapter is set" do
  it "should call it's enabled! method on init" do
    QueueBus.send(:reset)
    adapter_under_test_class.any_instance.should_receive(:enabled!)
    instance = adapter_under_test_class.new
    QueueBus.send(:reset)
  end

  it "should be defaulting to Data from spec_helper" do
    QueueBus.adapter.is_a?(adapter_under_test_class).should == true
  end

  context 'with no custom QueueBus Redis configuration' do

    let(:resque_url) { 'redis://localhost:6379/0' }
    let(:active_url) { ::Resque.redis.redis.client.options[:url] }

    before(:each) do
      Resque.redis = resque_url
    end

    it 'uses the default redis instance' do
      QueueBus.adapter.redis do
        active_url.should eq(resque_url)
      end
    end

  end

  context 'with a custom QueueBus Redis configuration' do
    let(:resque_url) { 'redis://localhost:6379/0' }
    let(:queuebus_url) { 'redis://localhost:6379/1' }

    before(:each) do
      Resque.redis = resque_url
      QueueBus.adapter.redis = queuebus_url
    end

    it 'still uses the default for Resque jobs' do
      ::Resque.redis.redis.client.options[:url].should eq(resque_url)
    end

    it 'uses the custom Redis instance for QueueBus jobs' do
      QueueBus.adapter.redis do
        ::Resque.redis.redis.client.options[:url].should eq(queuebus_url)
      end
    end

  end

end
