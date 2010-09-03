require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class TestForm < Larynx::Form; end

describe Larynx::Form do
  attr_reader :call

  before do
    @call = TestCallHandler.new(1)
  end

  context "#run" do
    it 'should call setup block' do
      this_should_be_called = should_be_called
      define_form do
        setup &this_should_be_called
      end.run(call)
    end
  end

  context "#restart_form" do
    it 'should call form setup block' do
      this_should_be_called = should_be_called
      form = define_form do
        setup &this_should_be_called
      end.new(call)
      form.restart_form
    end

    it 'should run the first field again' do
      form = define_form do
        field(:test1) { prompt :speak => '' }
        field(:test2) { prompt :speak => '' }
      end.new(call)

      form.fields[0].should_receive(:run).twice
      form.run
      form.next_field
      form.restart_form
    end
  end

  def define_form(&block)
    reset_class(TestForm) do
      instance_eval &block if block_given?
    end
  end

end
