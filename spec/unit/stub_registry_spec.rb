require 'spec_helper'

describe WebMock::StubRegistry do

  before(:each) do
    WebMock::StubRegistry.instance.reset!
    @request_pattern = WebMock::RequestPattern.new(:get, "www.example.com")
    @request_signature = WebMock::RequestSignature.new(:get, "www.example.com")
    @request_stub = WebMock::RequestStub.new(:get, "www.example.com")
  end

  describe "reset!" do
    before(:each) do
      WebMock::StubRegistry.instance.register_request_stub(@request_stub)
    end

    it "should clean request stubs" do
      WebMock::StubRegistry.instance.registered_request?(@request_signature).should == @request_stub
      WebMock::StubRegistry.instance.reset!
      WebMock::StubRegistry.instance.registered_request?(@request_signature).should == nil
    end
  end

  describe "reset_stub" do
    let(:stub11) { WebMock::RequestStub.new(:get, "www.example.com/123/?x=1") }
    let(:stub12) { WebMock::RequestStub.new(:get, "www.example.com/123/?x=2") }
    let(:stub13) { WebMock::RequestStub.new(:post, "www.example.com/123/?x=1") }
    let(:stub14) { WebMock::RequestStub.new(:post, "www.example.com/123/?x=2") }

    let(:stub21) { WebMock::RequestStub.new(:get, "www.example.com/234/?x=1") }
    let(:stub22) { WebMock::RequestStub.new(:get, "www.example.com/234/?x=2") }
    let(:stub23) { WebMock::RequestStub.new(:post, "www.example.com/234/?x=1") }
    let(:stub24) { WebMock::RequestStub.new(:post, "www.example.com/234/?x=2") }

    let(:instance) { WebMock::StubRegistry.instance }
    
    before do
      [stub11, stub12, stub13, stub14,
        stub21, stub22, stub23, stub24].each do |stub|
        instance.register_request_stub(stub)
      end
    end

    it "should return true if stub request removed" do
      instance.reset_stub(:get, /123\/.*=2$/).should be_true
    end

    it "should return false if stub request not found" do
      instance.reset_stub(:get, /123\/.*=3$/).should be_false
    end

    describe "checks reset stub request by uri_regexp" do
      before { instance.reset_stub(:get, /123\/.*=2$/) }
      subject { instance.request_stubs }
      it { should have(7).items }
      it { should_not include(stub12) }
    end

    describe "checks reset collection of stub" do
      before { instance.reset_stub(:get, /\/123\//) }
      subject { instance.request_stubs }
      it { should have(6).items }
      it { should_not include(stub11, stub11) }
    end

    describe "checks reset stub request by uri_regexp and request method" do
      before { instance.reset_stub(:post, /123\/.*=2$/) }
      subject { instance.request_stubs }
      it { should have(7).items }
      it { should_not include(stub14) }
    end

  end

  describe "registering and reporting registered requests" do

    it "should return registered stub" do
      WebMock::StubRegistry.instance.register_request_stub(@request_stub).should == @request_stub
    end

    it "should report if request stub is not registered" do
      WebMock::StubRegistry.instance.registered_request?(@request_signature).should == nil
    end

    it "should register and report registered stib" do
      WebMock::StubRegistry.instance.register_request_stub(@request_stub)
      WebMock::StubRegistry.instance.registered_request?(@request_signature).should == @request_stub
    end


  end

  describe "response for request" do

    it "should report registered evaluated response for request pattern" do
      @request_stub.to_return(:body => "abc")
      WebMock::StubRegistry.instance.register_request_stub(@request_stub)
      WebMock::StubRegistry.instance.response_for_request(@request_signature).
        should == WebMock::Response.new(:body => "abc")
    end

    it "should report evaluated response" do
      @request_stub.to_return {|request| {:body => request.method.to_s} }
      WebMock::StubRegistry.instance.register_request_stub(@request_stub)
      response1 = WebMock::StubRegistry.instance.response_for_request(@request_signature)
      response1.should == WebMock::Response.new(:body => "get")
    end

    it "should report clone of theresponse" do
      @request_stub.to_return {|request| {:body => request.method.to_s} }
      WebMock::StubRegistry.instance.register_request_stub(@request_stub)
      response1 = WebMock::StubRegistry.instance.response_for_request(@request_signature)
      response2 = WebMock::StubRegistry.instance.response_for_request(@request_signature)
      response1.should_not be(response2)
    end

    it "should report nothing if no response for request is registered" do
      WebMock::StubRegistry.instance.response_for_request(@request_signature).should == nil
    end

    it "should always return last registered matching response" do
      @request_stub1 = WebMock::RequestStub.new(:get, "www.example.com")
      @request_stub1.to_return(:body => "abc")
      @request_stub2 = WebMock::RequestStub.new(:get, "www.example.com")
      @request_stub2.to_return(:body => "def")
      @request_stub3 = WebMock::RequestStub.new(:get, "www.example.org")
      @request_stub3.to_return(:body => "ghj")
      WebMock::StubRegistry.instance.register_request_stub(@request_stub1)
      WebMock::StubRegistry.instance.register_request_stub(@request_stub2)
      WebMock::StubRegistry.instance.register_request_stub(@request_stub3)
      WebMock::StubRegistry.instance.response_for_request(@request_signature).
        should == WebMock::Response.new(:body => "def")
    end

  end

end
