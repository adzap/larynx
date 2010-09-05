require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class TestMenu < Larynx::Menu; end

describe Larynx::Menu do
  let(:call) { TestCallHandler.new(1) } 

  before do
    call.queue = []
  end

  it 'should allow a prompt to be defined' do
    define_menu do
      prompt :speak => 'For first option, press 1.'
    end
  end

  it 'should allow options to be defined' do
    define_menu do
      prompt :speak => 'For first option, press 1.'
      option(1) {  }
    end
  end

  it 'should execute prompt when run' do
    menu = define_menu do
      prompt :speak => 'For first option, press 1.'
      option(1) {  }
    end.new(call)
    menu.should_receive(:execute_prompt)
    menu.run
  end

  it 'should evaluate choice after user input' do
    menu = define_menu do
      prompt :speak => 'For first option, press 1.', :length => 1
    end.new(call)
    menu.run
    call.input << '1'
    menu.should_receive(:evaluate_choice)
    call.finalize_command
  end

  context "#last_attempt?" do
    it 'should return false when current attempt not equal to max attempts' do
      menu = define_menu do
        prompt :speak => 'For first option, press 1.', :length => 1, :attempts => 2
        option(1) { }
      end.new(call)
      menu.run
      menu.attempt.should == 1
      menu.last_attempt?.should be_false
    end

    it 'should return true when current attempt equals max attempts' do
      menu = define_menu do
        prompt :speak => 'For first option, press 1.', :length => 1, :attempts => 2
        option(1) { }
      end.new(call)
      menu.run
      menu.increment_attempts
      menu.attempt.should == 2
      menu.last_attempt?.should be_true
    end
  end

  context "choice evaluation" do
    it 'should evaluate option callbacks in menu object scope' do
      menu = define_menu do
        prompt :speak => 'For first option, press 1.', :length => 1
        option(1) { a_menu_method }
      end.new(call)
      menu.should_receive(:a_menu_method).and_return(true)
      menu.evaluate_choice('1')
    end

    it 'should execute matching menu option for choice value' do
      call_me = should_be_called
      menu = define_menu do
        prompt :speak => 'For first option, press 1.'
        option(1, &call_me)
      end.new(call)
      menu.evaluate_choice('1')
    end

    it 'should execute range menu option which includes choice value' do
      call_me_twice = should_be_called(2)
      menu = define_menu do
        prompt :speak => 'For first option, press 1.'
        option(1..2, &call_me_twice)
      end.new(call)
      menu.evaluate_choice('1')
      menu.evaluate_choice('2')
    end

    it 'should execute array menu option which includes choice value' do
      call_me_twice = should_be_called(2)
      menu = define_menu do
        prompt :speak => 'For first option, press 1.'
        option([1,2], &call_me_twice)
      end.new(call)
      menu.evaluate_choice('1')
      menu.evaluate_choice('2')
    end

    it 'should fire invalid callback when invalid choice made' do
      call_me = should_be_called
      menu = define_menu do
        prompt :speak => 'For first option, press 1.'
        option(1) {}
        invalid &call_me
      end.new(call)
      menu.evaluate_choice('0')
    end

    it 'should increment attempts after invalid choice' do
      menu = define_menu do
        prompt :speak => 'For first option, press 1.'
        option(1) {}
      end.new(call)
      menu.evaluate_choice('0')
      menu.attempt.should == 2
    end

    it 'should fire failure callback when no valid choice made after max attempts' do
      call_me = should_be_called
      menu = define_menu do
        prompt :speak => 'For first option, press 1.', :attempts => 2
        option(1) {}
        failure &call_me
      end.new(call)
      menu.evaluate_choice('0')
      menu.evaluate_choice('0')
    end
  end

  def define_menu(&block)
    reset_class(TestMenu) do
      instance_eval &block if block_given?
    end
  end
end
