require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class TestForm < Larynx::Form; end

describe Larynx::Form do
  let(:call) { TestCallHandler.new(1) }

  it 'should add field class method' do
    Larynx::Form.should respond_to(:field)
  end

  it 'should add instance accessor for field name' do
    form_class = define_form 
    form_class.field(:guess) { prompt :speak => 'hello' }
    form_class.methods.include?(:guess)
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

  context '#next_field' do
    let(:form) {
      define_form do
        field(:field1) { prompt :speak => 'hello' }
        field(:field2) { prompt :speak => 'hello' }
        field(:field3) { prompt :speak => 'hello' }
      end.new(call)
    }

    it 'should iterate over defined fields' do
      form.next_field.name.should == :field1
      form.next_field.name.should == :field2
      form.next_field.name.should == :field3
    end

    it 'should jump to field name if supplied' do
      form.next_field(:field2).name.should == :field2
    end
  end

  context "#current_field" do
    it 'should return field of current position' do
      form = define_form do
        field(:field1) { prompt :speak => 'hello' }
        field(:field2) { prompt :speak => 'hello' }
      end.new(call)
      form.run

      form.current_field.should == form.fields[0]
      form.next_field
      form.current_field.should == form.fields[1]
    end
  end

  def define_form(&block)
    reset_class(TestForm) do
      instance_eval &block if block_given?
    end
  end

end
