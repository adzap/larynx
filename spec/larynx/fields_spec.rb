require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Larynx::Fields do
  attr_reader :call, :app

  before do
    @call = TestCallHandler.new(1)
    @app = Larynx::Application.new(@call)
  end

  context 'module' do
    include Larynx::Fields

    it 'should add field class method' do
      self.class.should respond_to(:field)
    end

    it 'should add instance accessor for field name' do
      self.class.field(:guess) { prompt :speak => 'hello' }
      self.methods.include?(:guess)
    end
  end

  context 'next_field' do
    include Larynx::Fields
    field(:field1) { prompt :speak => 'hello' }
    field(:field2) { prompt :speak => 'hello' }
    field(:field3) { prompt :speak => 'hello' }

    it 'should iterate over defined fields' do
      next_field.name.should == :field1
      next_field.name.should == :field2
      next_field.name.should == :field3
    end

    it 'should jump to field name if supplied' do
      next_field(:field2).name.should == :field2
    end
  end

  context 'field object' do
    it 'should raise exception if field has no prompt' do
      lambda { field(:guess) {} }.should raise_exception(Larynx::NoPromptDefined)
    end

    it 'should run setup callback once' do
      call_me = should_be_called
      fld = field(:guess) do
        prompt :speak => 'first'
        setup &call_me
      end
      fld.run app
    end

    it 'should return same prompt all attempts if single prompt' do
      fld = field(:guess) do
        prompt :speak => 'first'
      end
      fld.run(app)
      fld.current_prompt.message.should == 'first'
      fld.increment_attempts
      fld.current_prompt.message.should == 'first'
    end

    it 'should return reprompt for subsequent prompts' do
      fld = field(:guess) do
        prompt :speak => 'first'
        reprompt :speak => 'second'
      end
      fld.run(app)
      fld.current_prompt.message.should == 'first'
      fld.increment_attempts
      fld.current_prompt.message.should == 'second'
    end

    it 'should return prompt for given number of repeats before subsequent prompts' do
      fld = field(:guess) do
        prompt :speak => 'first', :repeats => 2
        reprompt :speak => 'second'
      end
      fld.run(app)
      fld.current_prompt.message.should == 'first'
      fld.increment_attempts
      fld.current_prompt.message.should == 'first'
      fld.increment_attempts
      fld.current_prompt.message.should == 'second'
    end

    context 'valid?' do
      it 'should be false if input size less than minimum' do
        fld = field(:guess) do
          prompt :speak => 'first'
        end
        fld.run app
        fld.current_prompt.finalise
        fld.valid?.should be_false
      end

      it 'should run validate callback if input minimum length' do
        call_me = should_be_called
        fld = field(:guess, :min_length => 1) do
          prompt :speak => 'first'
          validate &call_me
        end
        fld.run app
        call.input << '1'
        fld.current_prompt.finalise
      end
    end

    context 'input evaluation' do
      it 'should run invalid callback if length not valid' do
        call_me = should_be_called
        fld = field(:guess) do
          prompt :speak => 'first'
          invalid &call_me
        end
        fld.run app
        fld.current_prompt.finalise
      end

      it 'should run invalid callback if validate callback returns false' do
        call_me = should_be_called
        fld = field(:guess, :min_length => 1) do
          prompt :speak => 'first'
          validate { false }
          invalid &call_me
        end
        fld.run app
        call.input << '1'
        fld.current_prompt.finalise
      end

      it 'should run success callback if length valid and no validate callback' do
        call_me = should_be_called
        fld = field(:guess, :min_length => 1) do
          prompt :speak => 'first'
          success &call_me
        end
        fld.run app
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
        fld.run app
        call.input << '1'
        fld.current_prompt.finalise
      end

      it 'should run failure callback if not valid and last attempt' do
        call_me = should_be_called
        fld = field(:guess, :min_length => 1, :attempts => 1) do
          prompt :speak => 'first'
          failure &call_me
        end
        fld.run app
        fld.current_prompt.finalise
      end

      it 'should increment attempts if not valid' do
        fld = field(:guess) do
          prompt :speak => 'first'
          reprompt :speak => 'second'
        end
        fld.run app
        fld.current_prompt.finalise
        fld.current_prompt.message.should == 'second'
      end

      it 'should execute next prompt if not valid' do
        fld = field(:guess) do
          prompt :speak => 'first'
          reprompt :speak => 'second'
        end
        fld.run app
        fld.should_receive(:execute_prompt)
        fld.current_prompt.finalise
      end
    end

  end

  def field(name, options={}, &block)
    @app.class.class_eval { attr_accessor name }
    Larynx::Fields::Field.new(name, options, &block)
  end
end