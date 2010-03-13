require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Freevoice::Prompt do
  attr_accessor :call

  before do
    @call = TestCallHandler.new(1)
    @call.queue = []
  end

  it "should raise error if no command value supplied" do
     lambda { Freevoice::Prompt.new(call, {}) }.should raise_exception(Freevoice::NoPromptCommandValue)
  end

  it "should return correct command name from options" do
    new_prompt(:speak  => 'Hello1').command_name.should == 'speak'
    new_prompt(:play   => 'Hello2').command_name.should == 'play'
    new_prompt(:phrase => 'Hello3').command_name.should == 'phrase'
  end

  it "should return correct message from options" do
    new_prompt(:speak  => 'Hello1').message.should == 'Hello1'
    new_prompt(:play   => 'Hello2').message.should == 'Hello2'
    new_prompt(:phrase => 'Hello3').message.should == 'Hello3'
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

  context "command" do
    it "should return command object for command name" do
      cmd = new_prompt.command
      cmd.should be_kind_of(Freevoice::AppCommand)
      cmd.command.should == 'speak'
    end
  end

  context "before callback" do
    it "should clear input on execution" do
      call.input << '1'
      before_callback new_prompt
      call.input.should be_empty
    end
  end

  context "after callback" do
    context "input completed" do
      it "should not add timers if reached length" do
        call.input << '1'
        call.should_not_receive(:timer).with(:digit, anything())
        call.should_not_receive(:timer).with(:input, anything())
        after_callback new_prompt
      end

      it "should not add timers if termchar input" do
        prompt = new_prompt(:speak => 'hello', :length => 2, :termchar => '#')
        call.input << '#'
        call.should_not_receive(:timer).with(:digit, anything())
        call.should_not_receive(:timer).with(:input, anything())
        after_callback prompt
      end

      it "should finalise prompt" do
        call.input << '#'
        prompt = new_prompt
        prompt.should_receive(:finalise)
        after_callback prompt
      end
    end

    context "input not completed" do
      it "should add timers" do
        call.should_receive(:timer).with(:digit, anything())
        call.should_receive(:timer).with(:input, anything())
        after_callback new_prompt
      end

      it "should add itself as call observer" do
        prompt = new_prompt
        call.stub!(:timer)
        after_callback prompt
        call.observers.should include(prompt)
      end

      it "should finalise prompt" do
        prompt = new_prompt(:speak => 'hello', :interdigit_timeout => 0.01) {|input| done }
        em do
          after_callback prompt
        end
      end
    end
  end

  context "finalize" do
    it "should run user callback" do
      prompt = new_prompt {|input| @callback = true }
      prompt.finalise
      @callback.should be_true
    end

    it "should remove prompt as call observer" do
      prompt = new_prompt
      call.should_receive(:remove_observer!).with(prompt)
      prompt.finalise
    end
  end

  context "user callback" do
    it "should be passed input argument equal to call input" do
      prompt = new_prompt {|input| @callback = '1'}
      call.input << '1'
      after_callback prompt
      @callback.should == '1'
    end
  end

  context "interdigit timeout" do
    it "should finalize prompt after specified number of seconds" do
      prompt = new_prompt(:speak => 'hello', :interdigit_timeout => 0.5) {|input| done }
      start = Time.now
      em do
        after_callback prompt
      end
      (Time.now-start).should be_close(0.5, 0.1)
    end

    it "should restart when DTMF received" do
      prompt = new_prompt(:speak => 'hello', :interdigit_timeout => 1) {|input| done }
      start = Time.now
      em do
        EM.add_timer(0.5) { prompt.dtmf_received('1') }
        after_callback prompt
      end
      (Time.now-start).should be_close(1.5, 0.2)
    end
  end

  context "timeout" do
    it "should finalize after number of seconds" do
      prompt = new_prompt(:speak => 'hello', :length => 5, :interdigit_timeout => 2, :timeout => 0.5) {|input| done }
      start = Time.now
      em do
        after_callback prompt
      end
      (Time.now-start).should be_close(0.5, 0.1)
    end

    it "should finalize after number of seconds even if digits being input" do
      prompt = new_prompt(:speak => 'hello', :length => 5, :interdigit_timeout => 1, :timeout => 1.5) {|input| done }
      start = Time.now
      em do
        EM.add_periodic_timer(0.5) { prompt.dtmf_received('1') }
        after_callback prompt
      end
      (Time.now-start).should be_close(1.5, 0.2)
    end
  end

  context "completion during timer" do
    it "should finalize before time out" do
      prompt = new_prompt(:speak => 'hello', :length => 1, :interdigit_timeout => 2) {|input| done }
      start = Time.now
      em do
        after_callback prompt
        EM.add_timer(0.5) { call.input << '1'; prompt.dtmf_received('1') }
      end
      (Time.now-start).should be_close(0.5, 0.2)
    end
  end

  def new_prompt(options=nil, &block)
    block = lambda { @callback = true } unless block_given?
    Freevoice::Prompt.new(call, options || {:speak => 'Hello world', :length => 1}, &block)
  end

  def before_callback(prompt)
    prompt.command.fire_callback :before
  end

  def after_callback(prompt)
    prompt.command.fire_callback :after
  end
end
