require "./spec_helper"

# Minimal test to verify Crystal syntax and structure
describe "WiredTiger Crystal Bindings" do
  it "can create exception objects" do
    ex = WiredTiger::DB::WiredTigerException.new("Test error")
    ex.message.should eq("Test error")
  end
  
  it "can create exception objects with cause" do
    cause = Exception.new("Original error")
    ex = WiredTiger::DB::WiredTigerException.new("Test error", cause)
    ex.message.should eq("Test error")
    ex.cause.should eq(cause)
  end
  
  it "has correct error constants" do
    WiredTiger::DB::Error::WT_NOTFOUND.should eq(-31803)
    WiredTiger::DB::Error::WT_PANIC.should eq(-31804)
    WiredTiger::DB::Error::WT_RUN_RECOVERY.should eq(-31805)
  end
end
