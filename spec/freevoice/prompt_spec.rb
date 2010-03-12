require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class TestCallHandler < Freevoice::CallHandler
  attr_accessor :send_data, :queue, :input

  def queue
    @queue
  end

  def send_data(msg)
    @sent_data = msg
  end

  def log(msg)
  end
end

describe Freevoice::Prompt do
  attr_accessor :call

  before do
    @call = TestCallHandler.new(1)
    @call.queue = []
  end

  it "should raise error if no command value supplied" do
     lambda { Freevoice::Prompt.new(call, {}) }.should raise_exception(Freevoice::NoPromptCommandValue)
  end

  it "should have correct output command from options" do
    new_prompt(:speak  => 'Hello').command.should == :speak
    new_prompt(:play   => 'Hello').command.should == :play
    new_prompt(:phrase => 'Hello').command.should == :phrase
  end

  context "input" do
    before do
      @prompt = new_prompt
    end

    it "should return call input as string" do
      call.input << '1'
      @prompt.input.should == '1'
    end

    it "should return call input without termchar" do
      call.input += ['1', '#']
      @prompt.input.should == '1'
    end
  end

  context "prompt_finished?" do
    it "should return true if input length reached" do
      prompt = new_prompt(:speak => 'hello', :length => 1)
      call.input << '1'
      prompt.prompt_finished?.should be_true
    end

    it "should return false if input length not reached" do
      prompt = new_prompt(:speak => 'hello', :length => 2)
      call.input << '1'
      prompt.prompt_finished?.should be_false
    end

    it "should return true if input has termchar regardless of length" do
      prompt = new_prompt(:speak => 'hello', :length => 2)
      call.input << '#'
      prompt.prompt_finished?.should be_true
    end

    it "should return true if input has reached max length" do
      prompt = new_prompt(:speak => 'hello', :max_length => 2)
      call.input += ['1', '2']
      prompt.prompt_finished?.should be_true
    end
  end

  context "execute" do
    before do
      new_prompt.execute
    end

    it "should queue a command" do
      call.queue.size.should == 1
      call.queue.first.name.should match('speak')
    end
  end

  context "callback" do
    it "should add digit and input timers" do
      new_prompt.execute
      call.should_receive(:timer).with(:digit, anything())
      call.should_receive(:timer).with(:input, anything())
      send_response :execute_complete
    end

    it "should not add timers if completed before callback" do
      new_prompt(:speak => 'Hello', :length => 1).execute
      call.input << '1'
      call.should_not_receive(:timer).with(:digit, anything())
      call.should_not_receive(:timer).with(:input, anything())
      send_response :execute_complete
    end

    it "should add digit and input timers if input received but incomplete" do
      new_prompt(:speak => 'hello', :length => 2).execute
      call.input << '1'
      call.should_receive(:timer).with(:digit, anything())
      call.should_receive(:timer).with(:input, anything())
      send_response :execute_complete
    end

    it "should not add timers if term char input but not complete" do
      new_prompt(:speak => 'hello', :length => 2, :termchar => '#').execute
      call.input << '#'
      call.should_not_receive(:timer).with(:digit, anything())
      call.should_not_receive(:timer).with(:input, anything())
      send_response :execute_complete
    end
  end

  context "user callback" do
    it "should be run when completed during prompt" do
      new_prompt {|input| @callback = true; done }.execute
      em do
        call.input << '1'
        send_response :execute_complete
      end
      @callback.should be_true
    end

    it "should be passed input argument equal to call input" do
      new_prompt {|input| @callback = '1'; done }.execute
      em do
        call.input << '1'
        send_response :execute_complete
      end
      @callback.should == '1'
    end
  end

  context "interdigit timeout" do
    it "should finalize prompt after specified number of seconds" do
      new_prompt(:speak => 'hello', :interdigit_timeout => 0.5) {|input| done }.execute
      start = Time.now
      em do
        send_response :execute_complete
      end
      (Time.now-start).should be_close(0.5, 0.1)
    end

    it "should restart when DTMF received" do
      prompt = new_prompt(:speak => 'hello', :interdigit_timeout => 1) {|input| done }
      prompt.execute
      start = Time.now
      em do
        EM.add_timer(0.5) { prompt.dtmf_received('1') }
        send_response :execute_complete
      end
      (Time.now-start).should be_close(1.5, 0.2)
    end
  end

  context "prompt timeout" do
    it "should finalize after number of seconds" do
      new_prompt(:speak => 'hello', :length => 5, :interdigit_timeout => 2, :timeout => 0.5) {|input| done }.execute
      start = Time.now
      em do
        send_response :execute_complete
      end
      (Time.now-start).should be_close(0.5, 0.1)
    end

    it "should finalize after number of seconds even if digits being input" do
      prompt = new_prompt(:speak => 'hello', :length => 5, :interdigit_timeout => 1, :timeout => 2) {|input| done }
      prompt.execute
      start = Time.now
      em do
        EM.add_periodic_timer(0.5) { prompt.dtmf_received('1') }
        send_response :execute_complete
      end
      (Time.now-start).should be_close(2, 0.2)
    end
  end

  def send_response(key)
    response = RESPONSES[key]
    call.receive_request(response[:header], response[:content])
  end

  def new_prompt(options=nil, &block)
    block = lambda { @callback = true } unless block_given?
    Freevoice::Prompt.new(call, options || {:speak => 'Hello world', :length => 1}, &block)
  end
end
