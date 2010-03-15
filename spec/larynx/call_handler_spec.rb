require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Larynx::CallHandler do
  attr_reader :call

  before do
    @call = TestCallHandler.new(1)
  end

  context "execute" do
    before do
      call.queue = []
    end

    it "should queue commands" do
      call.execute Larynx::Command.new('dummy1')
      call.execute Larynx::Command.new('dummy2')
      call.queue[0].command.should == 'dummy1'
      call.queue[1].command.should == 'dummy2'
    end

    it "should push command on front of queue when immediate is true" do
      call.execute Larynx::Command.new('dummy1')
      call.execute Larynx::Command.new('dummy2'), true
      call.queue[0].command.should == 'dummy2'
      call.queue[1].command.should == 'dummy1'
    end
  end

  it "should return first command in queue for current_command" do
    call.queue = []
    call.execute Larynx::Command.new('dummy')
    call.current_command.command.should == 'dummy'
  end

  it "should send current command message on send_next_command" do
    call.queue = []
    call.execute Larynx::Command.new('dummy')
    call.send_next_command
    call.sent_data.should == 'dummy'
  end

  context "initialisation" do
    it "should queue connect command on init" do
      em do
        call.current_command.name.should == 'connect'
        done
      end
    end
    it "should set state to initiated" do
      em do
        call.state.should == :initiated
        done
      end
    end
  end

  context "reply received" do
    it "should finalise current command if it is an API command"
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

  # TODO fix restart timer timing
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
