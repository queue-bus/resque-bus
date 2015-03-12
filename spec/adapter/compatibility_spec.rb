require 'spec_helper'

describe "Compatibility with old resque-bus" do
  before(:each) do
    ResqueBus.show_deprecations = false # expected

    QueueBus.dispatch("r1") do
      subscribe "event_name" do |attributes|
        QueueBus::Runner1.run(attributes)
      end
    end

    QueueBus::TaskManager.new(false).subscribe!

    @incoming = Resque::Worker.new(:resquebus_incoming)
    @incoming.register_worker

    @new_incoming = Resque::Worker.new(:bus_incoming)
    @new_incoming.register_worker

    @rider = Resque::Worker.new(:r1_default)
    @rider.register_worker
  end

  describe "Publisher" do
    it "should still publish as expected" do
      val = QueueBus.redis { |redis| redis.lpop("queue:resquebus_incoming") }
      val.should == nil
      
      args = [ "event_name", {"bus_event_type"=>"event_name", "two"=>"here", "one"=>1, "id" => 12} ]
      item = {:class => "ResqueBus::Publisher", :args => args}

      QueueBus.redis { |redis| redis.sadd(:queues, "resquebus_incoming") }
      QueueBus.redis { |redis| redis.rpush "queue:resquebus_incoming", Resque.encode(item) }

      QueueBus::Runner1.value.should == 0

      perform_next_job @incoming # publish

      QueueBus::Runner1.value.should == 0

      perform_next_job @new_incoming # drive

      QueueBus::Runner1.value.should == 0

      perform_next_job @rider # ride

      QueueBus::Runner1.value.should == 1

    end
  end

  describe "Rider" do
    it "should still ride as expected" do
      val = QueueBus.redis { |redis| redis.lpop("queue:r1_default") }
      val.should == nil

      args = [ {"bus_rider_app_key"=>"r1", "x" => "y", "bus_event_type" => "event_name", 
                "bus_rider_sub_key"=>"event_name", "bus_rider_queue" => "default", 
                "bus_rider_class_name"=>"::ResqueBus::Rider"}]
      item = {:class => "ResqueBus::Rider", :args => args}

      QueueBus.redis { |redis| redis.sadd(:queues, "r1_default") }
      QueueBus.redis { |redis| redis.rpush "queue:r1_default", Resque.encode(item) }

      QueueBus::Runner1.value.should == 0

      perform_next_job @rider

      QueueBus::Runner1.value.should == 1
    end
  end

  describe "Driver" do
    it "should still drive as expected" do
      val = QueueBus.redis { |redis| redis.lpop("queue:resquebus_incoming") }
      val.should == nil
      
      args = [ {"bus_event_type" => "event_name", "two"=>"here", "one"=>1, "id" => 12} ]
      item = {:class => "ResqueBus::Driver", :args => args}

      QueueBus.redis { |redis| redis.sadd(:queues, "resquebus_incoming") }
      QueueBus.redis { |redis| redis.rpush "queue:resquebus_incoming", Resque.encode(item) }

      QueueBus::Runner1.value.should == 0

      perform_next_job @incoming

      QueueBus::Runner1.value.should == 0

      perform_next_job @rider

      QueueBus::Runner1.value.should == 1

    end
  end
end
