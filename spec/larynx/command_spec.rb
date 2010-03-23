require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Larynx::Command do

  it "should allow before callback" do
    cmd = Larynx::Command.new('dummy').before { @callback = true }
    @callback.should_not be_true
    cmd.fire_callback :before
    @callback.should be_true
  end

  it "should allow after callback" do
    cmd = Larynx::Command.new('dummy').after  { @callback = true }
    @callback.should_not be_true
    cmd.fire_callback :after
    @callback.should be_true
  end

  it "should add block given to new as after block" do
    cmd = Larynx::Command.new('dummy') { @callback = true }
    @callback.should_not be_true
    cmd.fire_callback :after
    @callback.should be_true
  end

  context 'call command' do
    before do
      @cmd = Larynx::CallCommand.new('dummy', 'arg')
    end

    it "should return name as command and params" do
      @cmd.name.should == 'dummy arg'
    end

    it "should return to_s as full command message" do
      @cmd.to_s.should == "dummy arg\n\n"
    end
  end

  context 'api command' do
    before do
      @cmd = Larynx::ApiCommand.new('dummy', 'arg')
    end

    it "should return name as command and params" do
      @cmd.name.should == 'dummy arg'
    end

    it "should return to_s as full command message" do
      @cmd.to_s.should == "api dummy arg\n\n"
    end
  end

  context 'app command' do
    before do
      @cmd = Larynx::AppCommand.new('dummy', 'arg', :bargein => true)
    end

    it "should return name as command and params" do
      @cmd.name.should == "dummy 'arg'"
    end

    it "should return to_s as full command message" do
      @cmd.to_s.should == "sendmsg\ncall-command: execute\nexecute-app-name: dummy\nexecute-app-arg: arg\n\n"
    end

    it "should return to_s as with arg if no param" do
      cmd = Larynx::AppCommand.new('dummy')
      cmd.to_s.should == "sendmsg\ncall-command: execute\nexecute-app-name: dummy\n\n"
    end

    it "should return true for interruptable if bargein option is true" do
      @cmd.interruptable?.should be_true
    end
  end
end
