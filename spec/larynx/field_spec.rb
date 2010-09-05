require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class TestForm < Larynx::Form; end

describe Larynx::Field do
  let(:call) { TestCallHandler.new(1) }
  let(:form) { define_form.new(call) }

  before do
    call.queue = []
  end

  it 'should raise exception if field has no prompt' do
    lambda { field(:guess) {} }.should raise_exception(Larynx::NoPromptDefined)
  end

  it 'should run setup callback once' do
    call_me = should_be_called
    fld = field(:guess) do
      prompt :speak => 'first'
      setup &call_me
    end
    fld.run form
  end

  it 'should pass timeout and length options to the prompt object' do
    fld = field(:guess, :length => 1, :min_length => 1, :max_length => 2, :interdigit_timeout => 1, :timeout => 2) do
      prompt :speak => 'first'
    end
    fld.run(form)
    prompt = fld.current_prompt
    prompt.interdigit_timeout.should == 1
    prompt.timeout.should == 2
    prompt.minimum_length.should == 1
    prompt.maximum_length.should == 2
  end

  it 'should return same prompt all attempts if single prompt' do
    fld = field(:guess) do
      prompt :speak => 'first'
    end
    fld.run(form)
    fld.current_prompt.message.should == 'first'
    fld.increment_attempts
    fld.current_prompt.message.should == 'first'
  end

  it 'should return reprompt for subsequent prompts' do
    fld = field(:guess) do
      prompt :speak => 'first'
      reprompt :speak => 'second'
    end
    fld.run(form)
    fld.current_prompt.message.should == 'first'
    fld.increment_attempts
    fld.current_prompt.message.should == 'second'
  end

  it 'should return prompt for given number of repeats before subsequent prompts' do
    fld = field(:guess) do
      prompt :speak => 'first', :repeats => 2
      reprompt :speak => 'second'
    end
    fld.run(form)
    fld.current_prompt.message.should == 'first'
    fld.increment_attempts
    fld.current_prompt.message.should == 'first'
    fld.increment_attempts
    fld.current_prompt.message.should == 'second'
  end

  context "#last_attempt?" do
    it 'should return false when current attempt not equal to max attempts' do
      fld = field(:guess, :attempts => 2) do
        prompt :speak => 'first'
      end
      fld.run(form)
      fld.attempt.should == 1
      fld.last_attempt?.should be_false
    end

    it 'should return true when current attempt equals max attempts' do
      fld = field(:guess, :attempts => 2) do
        prompt :speak => 'first'
      end
      fld.run(form)
      fld.increment_attempts
      fld.attempt.should == 2
      fld.last_attempt?.should be_true
    end
  end

  context 'input evaluation' do
    it 'should evaluate callbacks in form object scope' do
      fld = field(:guess, :length => 1) do
        prompt :speak => 'first'
        validate { a_form_method }
      end
      form.should_receive(:a_form_method).and_return(true)
      fld.run(form)
      call.input << '1'
      fld.current_prompt.finalise
    end

    it 'should run validate callback if input minimum length' do
      call_me = should_be_called
      fld = field(:guess, :min_length => 1) do
        prompt :speak => 'first'
        validate &call_me
      end
      fld.run form
      call.input << '1'
      fld.current_prompt.finalise
    end

    it 'should run invalid callback if length not valid' do
      call_me = should_be_called
      fld = field(:guess) do
        prompt :speak => 'first'
        invalid &call_me
      end
      fld.run form
      fld.current_prompt.finalise
    end

    it 'should run invalid callback if validate callback returns false' do
      call_me = should_be_called
      fld = field(:guess, :min_length => 1) do
        prompt :speak => 'first'
        validate { false }
        invalid &call_me
      end
      fld.run form
      call.input << '1'
      fld.current_prompt.finalise
    end

    it 'should run invalid callback if validate callback returns nil' do
      call_me = should_be_called
      fld = field(:guess, :min_length => 1) do
        prompt :speak => 'first'
        validate { nil }
        invalid &call_me
      end
      fld.run form
      call.input << '1'
      fld.current_prompt.finalise
    end

    it 'should run success callback if length valid and no validate callback' do
      call_me = should_be_called
      fld = field(:guess, :min_length => 1) do
        prompt :speak => 'first'
        success &call_me
      end
      fld.run form
      call.input << '1'
      fld.current_prompt.finalise
    end

    it 'should run success callback if validate callback returns true' do
      call_me = should_be_called
      fld = field(:guess, :min_length => 1) do
        prompt :speak => 'first'
        validate { true }
        success &call_me
      end
      fld.run form
      call.input << '1'
      fld.current_prompt.finalise
    end

    it 'should run failure callback if not valid and last attempt' do
      call_me = should_be_called
      fld = field(:guess, :min_length => 1, :attempts => 1) do
        prompt :speak => 'first'
        failure &call_me
      end
      fld.run form
      fld.current_prompt.finalise
    end

    it 'should increment attempts if not valid' do
      fld = field(:guess) do
        prompt :speak => 'first'
        reprompt :speak => 'second'
      end
      fld.run form
      fld.current_prompt.finalise
      fld.current_prompt.message.should == 'second'
    end

    it 'should execute next prompt if not valid' do
      fld = field(:guess) do
        prompt :speak => 'first'
        reprompt :speak => 'second'
      end
      fld.run form
      fld.should_receive(:execute_prompt)
      fld.current_prompt.finalise
    end

    context "async callbacks" do
      # it "should be run in thread" do
      #   em do
      #     fld = field(:guess) do
      #       prompt :speak => 'first'
      #       validate(:async) { sleep(0.25) }
      #       success { done }
      #     end.run(form)
      #     call.input << '1'
      #   end
      #   @callback.should be_nil
      # end
    end

  end

  def field(name, options={}, &block)
    form.class.class_eval { attr_accessor name }
    Larynx::Field.new(name, options, &block)
  end

  def define_form(&block)
    reset_class(TestForm) do
      instance_eval &block if block_given?
    end
  end
end
