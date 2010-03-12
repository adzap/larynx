require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe EventMachine do

  it "should allow timer to be restarted" do
    start = Time.now
    em do
      timer = EM::Timer.new(1) { done }
      EM::Timer.new(0.5) { timer.restart }
    end
    (Time.now-start).should be_close(1.5, 0.2)
  end

end
