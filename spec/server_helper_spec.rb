require 'spec_helper'
require_relative '../lib/resque_bus/server'

describe "Web Server Helper" do
  describe ".parse_query" do
    it "should pass through valid json" do
      input = %Q{ 
        { "name": "here", "number": 1, "bool": true } 
      }
      output = {"name"=>"here", "number"=>1, "bool"=>true}
      check = ::ResqueBus::Server::Helpers.parse_query(input)
      check.should == output
    end

    it "should handle multi-line json" do
      input = %Q{ 
        { 
          "name": "here",
          "number": 1,
          "bool": true
        } 
      }
      output = {"name"=>"here", "number"=>1, "bool"=>true}
      check = ::ResqueBus::Server::Helpers.parse_query(input)
      check.should == output
    end

    it "should interpret simple string as bus_event_type" do
      input = %Q{ user_created }
      output = {"bus_event_type" => "user_created", "more_here" => true}
      check = ::ResqueBus::Server::Helpers.parse_query(input)
      check.should == output
    end

    it "should raise error on valid json that's not an Object" do
      input = '[{ "name": "here" }]'
      lambda {
        ::ResqueBus::Server::Helpers.parse_query(input)
      }.should raise_error("Not a JSON Object")
    end

    it "should allow array from resque server panel with encoded json string arg array" do
      input = '["{\"name\":\"here\"}"]'
      output = {"name" => "here"}
      check = ::ResqueBus::Server::Helpers.parse_query(input)
      check.should == output
    end

    it "should take in a arg list and make it json" do
      input = %Q{
        bus_event_type: my_event
        user_updated: true
      }
      output = {"bus_event_type" => "my_event", "user_updated" => "true"}
      check = ::ResqueBus::Server::Helpers.parse_query(input)
      check.should == output
    end

    it "should take in an arg list with quoted json and commas" do
      input = %Q{
        "bus_event_type": "my_event",
        "user_updated": true
      }
      output = {"bus_event_type" => "my_event", "user_updated" => true}
      check = ::ResqueBus::Server::Helpers.parse_query(input)
      check.should == output
    end

    it "should parse logged output from event.inspect" do
      input = %Q{
        {"bus_published_at"=>1563793250, "bus_event_type"=>"user_created", :user_id=>42, :name=>"Brian" }
      }
      output = {
        "bus_published_at" => 1563793250,
        "bus_event_type" => "user_created",
        "user_id" => 42,
        "name" => "Brian"
      }
      check = ::ResqueBus::Server::Helpers.parse_query(input)
      check.should == output
    end

    it "should throw json parse error when it can't be handled" do
      input = '{ "name": "here" q }'
      lambda {
        ::ResqueBus::Server::Helpers.parse_query(input)
      }.should raise_error(/unexpected token/)
    end
  end

  describe ".sort_query" do
    it "should alphabetize a query hash" do
      input = {"cat" => true, "apple" => true, "dog" => true, "bear" => true}
      output = {"apple" => true, "bear" => true, "cat" => true, "dog" => true }
      check = ::ResqueBus::Server::Helpers.sort_query(input)
      check.should == output
    end

    it "should alphabetize a query sub-hashes but not arrays" do
      input = {"cat" => true, "apple" => [
        "jackal", "kangaroo", "iguana"
      ], "dog" => {
        "frog" => 11, "elephant" => 12, "hare" => 16, "goat" => 14
      }, "bear" => true}
      output = {"apple" => [
        "jackal", "kangaroo", "iguana"
      ], "bear" => true, "cat" => true, "dog" => {
        "elephant" => 12, "frog" => 11, "goat" => 14, "hare" => 16
      }}
      check = ::ResqueBus::Server::Helpers.sort_query(input)
      check.should == output
    end
  end
end
