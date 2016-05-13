require 'spec_helper'

describe QueueBus::Subscriber do
  let(:attributes) { {"x" => "y"} }
  let(:bus_attrs) { {"bus_driven_at" => Time.now.to_i} }

  before(:each) do
    class SubscriberTest1
      include QueueBus::Subscriber
      @queue = "myqueue"

      application :my_thing
      subscribe :thing_filter, :x => "y"
      subscribe :event_sub

      def event_sub(attributes)
        QueueBus::Runner1.run(attributes)
      end

      def thing_filter(attributes)
        QueueBus::Runner2.run(attributes)
      end
    end

    class SubscriberTest2
      include QueueBus::Subscriber
      application :test2
      subscribe :test2,  "value" => :present
      transform :make_an_int

      def self.make_an_int(attributes)
        attributes["value"].to_s.length
      end

      def test2(int)
        QueueBus::Runner1.run("transformed"=>int)
      end
    end

    module SubModule
      class SubscriberTest3
        include QueueBus::Subscriber

        subscribe_queue :sub_queue1, :test3, :bus_event_type => "the_event"
        subscribe_queue :sub_queue2, :the_event
        subscribe :other, :bus_event_type => "other_event"

        def test3(attributes)
          QueueBus::Runner1.run(attributes)
        end

        def the_event(attributes)
          QueueBus::Runner2.run(attributes)
        end
      end

      class SubscriberTest4
        include QueueBus::Subscriber

        subscribe_queue :sub_queue1, :test4
      end
    end

    Timecop.freeze
    QueueBus::TaskManager.new(false).subscribe!
  end

  after(:each) do
    Timecop.return
  end

  it "should have the application" do
    SubscriberTest1.app_key.should == "my_thing"
    SubModule::SubscriberTest3.app_key.should == "sub_module"
    SubModule::SubscriberTest4.app_key.should == "sub_module"
  end

  it "should be able to transform the attributes" do
    dispatcher = QueueBus.dispatcher_by_key("test2")
    all = dispatcher.subscriptions.all
    all.size.should == 1

    sub = all.first
    sub.queue_name.should == "test2_default"
    sub.class_name.should == "SubscriberTest2"
    sub.key.should == "SubscriberTest2.test2"
    sub.matcher.filters.should == {"value"=>"bus_special_value_present"}

    QueueBus::Driver.perform(attributes.merge("bus_event_type" => "something2", "value"=>"nice"))

    hash = JSON.parse(QueueBus.redis { |redis| redis.lpop("queue:test2_default") })
    hash["class"].should == "QueueBus::Worker"
    hash["args"].size.should == 1
    JSON.parse(hash["args"].first).should eq({"bus_class_proxy" => "SubscriberTest2", "bus_rider_app_key"=>"test2", "bus_rider_sub_key"=>"SubscriberTest2.test2", "bus_rider_queue" => "test2_default", "bus_rider_class_name"=>"SubscriberTest2",
                             "bus_event_type" => "something2", "value"=>"nice", "x"=>"y"}.merge(bus_attrs))

    QueueBus::Runner1.value.should == 0
    QueueBus::Runner2.value.should == 0
    QueueBus::Util.constantize(hash["class"]).perform(*hash["args"])
    QueueBus::Runner1.value.should == 1
    QueueBus::Runner2.value.should == 0

    QueueBus::Runner1.attributes.should == {"transformed" => 4}


    QueueBus::Driver.perform(attributes.merge("bus_event_type" => "something2", "value"=>"12"))

    hash = JSON.parse(QueueBus.redis { |redis| redis.lpop("queue:test2_default") })
    hash["class"].should == "QueueBus::Worker"
    hash["args"].size.should == 1
    JSON.parse(hash["args"].first).should == {"bus_class_proxy" => "SubscriberTest2", "bus_rider_app_key"=>"test2", "bus_rider_sub_key"=>"SubscriberTest2.test2", "bus_rider_queue" => "test2_default", "bus_rider_class_name"=>"SubscriberTest2",
                             "bus_event_type" => "something2", "value"=>"12", "x"=>"y"}.merge(bus_attrs)

    QueueBus::Runner1.value.should == 1
    QueueBus::Runner2.value.should == 0
    QueueBus::Util.constantize(hash["class"]).perform(*hash["args"])
    QueueBus::Runner1.value.should == 2
    QueueBus::Runner2.value.should == 0

    QueueBus::Runner1.attributes.should == {"transformed" => 2}
  end


  it "should put in a different queue" do
    dispatcher = QueueBus.dispatcher_by_key("sub_module")
    all = dispatcher.subscriptions.all
    all.size.should == 4

    sub = all.select{ |s| s.key == "SubModule::SubscriberTest3.test3"}.first
    sub.queue_name.should == "sub_queue1"
    sub.class_name.should == "SubModule::SubscriberTest3"
    sub.key.should == "SubModule::SubscriberTest3.test3"
    sub.matcher.filters.should == {"bus_event_type"=>"the_event"}

    sub = all.select{ |s| s.key == "SubModule::SubscriberTest3.the_event"}.first
    sub.queue_name.should == "sub_queue2"
    sub.class_name.should == "SubModule::SubscriberTest3"
    sub.key.should == "SubModule::SubscriberTest3.the_event"
    sub.matcher.filters.should == {"bus_event_type"=>"the_event"}

    sub = all.select{ |s| s.key == "SubModule::SubscriberTest3.other"}.first
    sub.queue_name.should == "sub_module_default"
    sub.class_name.should == "SubModule::SubscriberTest3"
    sub.key.should == "SubModule::SubscriberTest3.other"
    sub.matcher.filters.should == {"bus_event_type"=>"other_event"}

    sub = all.select{ |s| s.key == "SubModule::SubscriberTest4.test4"}.first
    sub.queue_name.should == "sub_queue1"
    sub.class_name.should == "SubModule::SubscriberTest4"
    sub.key.should == "SubModule::SubscriberTest4.test4"
    sub.matcher.filters.should == {"bus_event_type"=>"test4"}

    QueueBus::Driver.perform(attributes.merge("bus_event_type" => "the_event"))

    hash = JSON.parse(QueueBus.redis { |redis| redis.lpop("queue:sub_queue1") })
    hash["class"].should == "QueueBus::Worker"
    hash["args"].size.should == 1
    JSON.parse(hash["args"].first).should == {"bus_class_proxy" => "SubModule::SubscriberTest3", "bus_rider_app_key"=>"sub_module", "bus_rider_sub_key"=>"SubModule::SubscriberTest3.test3", "bus_rider_queue" => "sub_queue1", "bus_rider_class_name"=>"SubModule::SubscriberTest3",
                              "bus_event_type" => "the_event", "x" => "y"}.merge(bus_attrs)

    QueueBus::Runner1.value.should == 0
    QueueBus::Runner2.value.should == 0
    QueueBus::Util.constantize(hash["class"]).perform(*hash["args"])
    QueueBus::Runner1.value.should == 1
    QueueBus::Runner2.value.should == 0

    hash = JSON.parse(QueueBus.redis { |redis| redis.lpop("queue:sub_queue2") })
    hash["class"].should == "QueueBus::Worker"
    hash["args"].size.should == 1
    JSON.parse(hash["args"].first).should == {"bus_class_proxy" => "SubModule::SubscriberTest3", "bus_rider_app_key"=>"sub_module", "bus_rider_sub_key"=>"SubModule::SubscriberTest3.the_event", "bus_rider_queue" => "sub_queue2", "bus_rider_class_name"=>"SubModule::SubscriberTest3",
                              "bus_event_type" => "the_event", "x" => "y"}.merge(bus_attrs)

    QueueBus::Runner1.value.should == 1
    QueueBus::Runner2.value.should == 0
    QueueBus::Util.constantize(hash["class"]).perform(*hash["args"])
    QueueBus::Runner1.value.should == 1
    QueueBus::Runner2.value.should == 1
  end

  it "should subscribe to default and attributes" do
    dispatcher = QueueBus.dispatcher_by_key("my_thing")
    all = dispatcher.subscriptions.all

    sub = all.select{ |s| s.key == "SubscriberTest1.event_sub"}.first
    sub.queue_name.should == "myqueue"
    sub.class_name.should == "SubscriberTest1"
    sub.key.should == "SubscriberTest1.event_sub"
    sub.matcher.filters.should == {"bus_event_type"=>"event_sub"}

    sub = all.select{ |s| s.key == "SubscriberTest1.thing_filter"}.first
    sub.queue_name.should == "myqueue"
    sub.class_name.should == "SubscriberTest1"
    sub.key.should == "SubscriberTest1.thing_filter"
    sub.matcher.filters.should == {"x"=>"y"}

    QueueBus::Driver.perform(attributes.merge("bus_event_type" => "event_sub"))
    QueueBus.redis { |redis| redis.smembers("queues") }.should =~ ["myqueue"]

    pop1 = JSON.parse(QueueBus.redis { |redis| redis.lpop("queue:myqueue") })
    pop2 = JSON.parse(QueueBus.redis { |redis| redis.lpop("queue:myqueue") })

    if JSON.parse(pop1["args"].first)["bus_rider_sub_key"] == "SubscriberTest1.thing_filter"
      hash1 = pop1
      hash2 = pop2
    else
      hash1 = pop2
      hash2 = pop1
    end

    hash1["class"].should == "QueueBus::Worker"
    JSON.parse(hash1["args"].first).should eq({"bus_class_proxy" => "SubscriberTest1", "bus_rider_app_key"=>"my_thing", "bus_rider_sub_key"=>"SubscriberTest1.thing_filter", "bus_rider_queue" => "myqueue", "bus_rider_class_name"=>"SubscriberTest1",
                              "bus_event_type" => "event_sub", "x" => "y"}.merge(bus_attrs))

    QueueBus::Runner1.value.should == 0
    QueueBus::Runner2.value.should == 0
    QueueBus::Util.constantize(hash1["class"]).perform(*hash1["args"])
    QueueBus::Runner1.value.should == 0
    QueueBus::Runner2.value.should == 1

    hash2["class"].should == "QueueBus::Worker"
    hash2["args"].size.should == 1
    JSON.parse(hash2["args"].first).should == {"bus_class_proxy" => "SubscriberTest1", "bus_rider_app_key"=>"my_thing", "bus_rider_sub_key"=>"SubscriberTest1.event_sub", "bus_rider_queue" => "myqueue", "bus_rider_class_name"=>"SubscriberTest1",
                              "bus_event_type" => "event_sub", "x" => "y"}.merge(bus_attrs)

    QueueBus::Runner1.value.should == 0
    QueueBus::Runner2.value.should == 1
    QueueBus::Util.constantize(hash2["class"]).perform(*hash2["args"])
    QueueBus::Runner1.value.should == 1
    QueueBus::Runner2.value.should == 1

    QueueBus::Driver.perform(attributes.merge("bus_event_type" => "event_sub_other"))
    QueueBus.redis { |redis| redis.smembers("queues") }.should =~ ["myqueue"]

    hash = JSON.parse(QueueBus.redis { |redis| redis.lpop("queue:myqueue") })
    hash["class"].should == "QueueBus::Worker"
    hash["args"].size.should == 1
    JSON.parse(hash["args"].first).should == {"bus_class_proxy" => "SubscriberTest1", "bus_rider_app_key"=>"my_thing", "bus_rider_sub_key"=>"SubscriberTest1.thing_filter", "bus_rider_queue" => "myqueue", "bus_rider_class_name"=>"SubscriberTest1",
                              "bus_event_type" => "event_sub_other", "x" => "y"}.merge(bus_attrs)

    QueueBus::Runner1.value.should == 1
    QueueBus::Runner2.value.should == 1
    QueueBus::Util.constantize(hash["class"]).perform(*hash["args"])
    QueueBus::Runner1.value.should == 1
    QueueBus::Runner2.value.should == 2

    QueueBus::Driver.perform({"x"=>"z"}.merge("bus_event_type" => "event_sub_other"))
    QueueBus.redis { |redis| redis.smembers("queues") }.should =~ ["myqueue"]

    QueueBus.redis { |redis| redis.lpop("queue:myqueue") }.should be_nil
  end

  describe ".perform" do
    let(:attributes) { {"bus_rider_sub_key"=>"SubscriberTest1.event_sub", "bus_locale" => "en", "bus_timezone" => "PST"} }
    it "should call the method based on key" do
      SubscriberTest1.any_instance.should_receive(:event_sub)
      SubscriberTest1.perform(attributes)
    end
    it "should set the timezone and locale if present" do
      defined?(I18n).should be_nil
      Time.respond_to?(:zone).should eq(false)

      stub_const("I18n", Class.new)
      I18n.should_receive(:locale=).with("en")
      Time.should_receive(:zone=).with("PST")

      SubscriberTest1.any_instance.should_receive(:event_sub)
      SubscriberTest1.perform(attributes)
    end

    context 'when a custom Queuebus Redis is used' do
      let(:resque_url) { 'redis://localhost:6379/0' }
      let(:queuebus_url) { 'redis://localhost:6379/1' }

      before(:each) do
        Resque.redis = resque_url
        QueueBus.adapter.redis = queuebus_url
        QueueBus.adapter.queuebus_redis
        Resque.redis = QueueBus.adapter.queuebus_redis
      end

      context 'with a well-behaved subscriber' do
        before(:each) do
          class SubscriberTest5
            include QueueBus::Subscriber
            @queue = "myqueue"
            subscribe :event_sub
            def event_sub(attributes)
              ::Resque.redis.redis.client.options[:url]
            end
          end
        end

        it 'should use the local Resque' do
          redis_url = SubscriberTest5.perform(attributes)
          redis_url.should eq(resque_url)
        end

        it 'should restore the queuebus redis' do
          SubscriberTest5.perform(attributes)
          Resque.redis.should eq(QueueBus.adapter.queuebus_redis)
        end
      end

      context 'when the subscriber throws an error' do
        before(:each) do
          class SubscriberTest5
            include QueueBus::Subscriber
            @queue = "myqueue"
            subscribe :event_sub
            def event_sub(attributes)
              raise StandardError
            end
          end
        end

        it 'should restore the queuebus redis' do
          lambda do
            SubscriberTest5.perform(attributes)
          end.should raise_error
          Resque.redis.should eq(QueueBus.adapter.queuebus_redis)
        end
      end
    end
  end
end
