require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Freevoice::CallHandler do
  attr_reader :call

  before do
    @call = TestCallHandler.new(1)
    @call.queue = []
  end

  context "execute" do
    it "should queue commands" do
      call.execute Freevoice::Command.new('dummy1')
      call.execute Freevoice::Command.new('dummy2')
      call.queue[0].command.should == 'dummy1'
      call.queue[1].command.should == 'dummy2'
    end

    it "should push command on front of queue when immediate is true" do
      call.execute Freevoice::Command.new('dummy1')
      call.execute Freevoice::Command.new('dummy2'), true
      call.queue[0].command.should == 'dummy2'
      call.queue[1].command.should == 'dummy1'
    end
  end

  it "should return first command in queue for current_command" do
    call.execute Freevoice::Command.new('dummy')
    call.current_command.command.should == 'dummy'
  end

  it "should send current command message on execute_next_command" do
    call.execute Freevoice::Command.new('dummy')
    call.execute_next_command
    call.sent_data.should == 'dummy'
  end

  context "timer" do
    it "should add EM timer with name and timeout" do
      EM::Timer.stub!(:new)
      call.timer(:test, 0.1)
      call.timers[:test].should_not be_nil
    end

    it "should run callback on timeout" do
      em do
        call.timer(:test, 0.2) { @callback = true; done }
      end
      @callback.should be_true
    end
  end

  context "stop_timer" do
    it "should run callback on timeout" do
      em do
        call.timer(:test, 1) { @callback = true }
        EM::Timer.new(0.1) { call.stop_timer :test; done }
      end
      @callback.should be_true
    end
  end

  context "cancel_timer" do
    it "should not run callback" do
      em do
        call.timer(:test, 0.2) { @callback = true }
        EM::Timer.new(0.1) { call.cancel_timer :test; done }
      end
      @callback.should_not be_true
    end
  end

  # context "restart_timer" do
  #   it "should start timer again" do
  #     start = Time.now
  #     puts "#{Time.now.sec}.#{Time.now.usec}"
  #     em do
  #       EM::Timer.new(0.1) { puts "#{Time.now.sec}.#{Time.now.usec}"; call.restart_timer :test }
  #       call.timer(:test, 0.2) { puts "#{Time.now.sec}.#{Time.now.usec}"; done }
  #     end
  #     (Time.now-start).should be_close(0.3, 0.06)
  #   end
  # end

end
