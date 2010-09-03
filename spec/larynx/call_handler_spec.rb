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

  context "reply received" do
    before do
      call.queue = []
    end

    it "should finalise current command if it is an API command" do
      call.should_receive :finalize_command
      call.connect
      call.send_response :reply_ok
    end

    it "should not finalise current command if it is an App command" do
      call.should_not_receive :finalize_command
      call.speak 'hello'
      call.send_response :reply_ok
    end
  end

  context "executing event received" do
    before do
      call.queue = []
    end

    it "should run app command before callback" do
      call.speak('hello world').before &should_be_called
      call.send_response :execute
    end

    it "should change state to executing" do
      call.speak 'hello'
      call.send_response :execute
      call.state.should == :executing
    end

    it "should not finalize command" do
      call.should_not_receive :finalize_command
      call.speak 'hello'
      call.send_response :execute
    end
  end

  context "execution complete event received" do
    before do
      call.queue = []
    end

    it "should finalize command" do
      call.should_receive :finalize_command
      call.speak 'hello'
      call.send_response :execute_complete
    end

    it "should change state to ready" do
      call.speak 'hello'
      call.send_response :execute_complete
      call.state.should == :ready
    end
  end

  context "finalizing command" do
    before do
      call.queue = []
      call.speak('hello world').after { @callback = true }
      @command = call.current_command
      call.finalize_command
    end

    it "should run after callback" do
      @callback.should be_true
    end

    it "should remove command from queue" do
      call.queue.should be_empty
    end

    it "should set command as last command" do
      call.last_command.should == @command
    end
  end

	it "should queue connect command on init" do
		call.current_command.name.should == 'connect'
	end

  context "on connection" do
    it "should create session object" do
      connect_call
      call.session.should_not be_nil
    end

    it "should fire global connect callback" do
      with_global_callback(:connect, should_be_called) do
        connect_call
      end
    end

    it "should subscribe to myevents" do
      call.should_receive(:myevents)
      connect_call
    end

    it "should set event lingering on after filter events" do
      call.should_receive(:linger)
      connect_call
    end

    it "should start the call session" do
      call.should_receive :start_session
      connect_call
    end

    def connect_call
      call.send_response :channel_data
    end

  end

  context "#session_start" do
    before do
      call.queue = []
      call.session = mock('session', :unique_id => '123')
      call.response = mock('response', :header => {})
    end

    it "should subscribe to events" do
      call.should_receive(:myevents)
      call.start_session
    end

    it "should execute linger command" do
      call.should_receive(:linger)
      call.start_session
    end

    it "should run answer command in connect callback be default" do
      call.should_receive(:answer)
      call.start_session
    end
  end

  context "on answer" do
    before do
      call.queue    = []
      call.session  = mock('session', :unique_id => '123')
      call.response = mock('response', :header => {})
    end

    it "should change state to ready" do
      answer_call
      call.state.should == :ready
    end

    it "should fire global answer callback" do
      with_global_callback(:answer, should_be_called) do
        answer_call
      end
    end

    it "should send next command if state is ready" do
      call.should_receive(:send_next_command)
      answer_call
    end

    it "should not send next command if answer callback changed state" do
      call.should_not_receive(:send_next_command)
      with_global_callback(:answer, lambda { call.state = :sending }) do
        answer_call
      end
    end

    def answer_call
      call.send_response :answered
    end
  end

  context "DTMF event" do
    it "should add DTMF digit to input" do
      run_command
      call.send_response :dtmf
      call.input.should == ['1']
    end

    it "should send break if interruptable command" do
      run_command true
      call.send_response :dtmf
      call.sent_data.should match(/break/)
    end

    it "should not send break if non-interruptable command" do
      run_command false
      call.send_response :dtmf
      call.sent_data.should_not match(/break/)
    end

    it "should send next command if state is ready" do
      call.state = :ready
      call.should_receive(:send_next_command)
      call.send_response :dtmf
    end

    it "should notify observers and pass digit" do
      app = mock('App')
      call.add_observer app
      app.should_receive(:dtmf_received).with('1')
      call.send_response :dtmf
    end

    def run_command(interruptable=true)
      call.queue = []
      call.speak 'hello', :bargein => interruptable
      call.send_next_command
      call.send_response :execute
    end
  end

  context "interrupting a command" do
    before do
      call.queue = []
      @executing_command = call.speak('hello', :bargein => true) { call.speak 'next hello' }
      call.send_next_command
      call.send_response :execute
      call.interrupt_command
    end

    it "should push break onto front of queue" do
      call.queue[0].command.should == 'break'
      call.queue[1].should == @executing_command
    end

    it "should execute break immediately" do
      call.sent_data.should match(/break/)
    end

    it "should set executing command to interrupted" do
      @executing_command.interrupted?.should be_true
    end

    it "should fire callback of interrupted command when break execute complete" do
      @executing_command.should_receive(:fire_callback).with(:after).once
      call.send_response :execute_complete
    end

    it "should leave executing command in queue" do
      call.send_response :execute_complete
      call.queue[0].should == @executing_command
    end

    it "should execute next command after interrupted command" do
      call.send_response :execute_complete
      call.sent_data.should match(/next hello/)
    end

    it "should not fire callback of interrupted command once execute complete" do
      call.send_response :execute_complete
      @executing_command.should_not_receive(:fire_callback).with(:after)
      call.send_response :execute_complete
    end
  end

  context "timer" do
    it "should add EM timer with name and timeout" do
      Larynx::RestartableTimer.stub!(:new)
      call.add_timer(:test, 0.1)
      call.timers[:test].should_not be_nil
    end

    it "should run callback on timeout" do
      em do
        call.add_timer(:test, 0.2) { @callback = true; done }
      end
      @callback.should be_true
    end
  end

  context "stop_timer" do
    it "should run callback on timeout" do
      em do
        call.add_timer(:test, 1, &should_be_called)
        EM::Timer.new(0.1) { call.stop_timer :test; done }
      end
    end
  end

  context "cancel_timer" do
    it "should not run callback" do
      em do
        call.add_timer(:test, 0.2, &should_not_be_called)
        EM::Timer.new(0.1) { call.cancel_timer :test; done }
      end
    end
  end

  context "restart_timer" do
    it "should start timer again" do
      start = Time.now
      em do
        EM::Timer.new(0.5) { call.restart_timer :test }
        call.add_timer(:test, 1) { done }
      end
      (Time.now-start).should be_close(1.5, 0.2)
    end
  end

end
