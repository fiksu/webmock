module WebMock

  class StubRegistry
    include Singleton

    attr_accessor :request_stubs

    def initialize
      reset!
    end

    def global_stubs
      @global_stubs ||= []
    end

    def reset!
      self.request_stubs = []
    end

    # Find and remove request_stub by request method and uri_regexp
    # returns true if request_stub found
    def reset_stub(method, uri_regexp)
      method = method.to_s
      request_stubs_count = self.request_stubs.count
      self.request_stubs.delete_if do |stub|
        method_str = stub.request_pattern.method_pattern.to_s
        uri_str = stub.request_pattern.uri_pattern.to_s
        method_str == method && uri_str =~ uri_regexp
      end
      request_stubs_count != self.request_stubs.count
    end

    def register_global_stub(&block)
      # This hash contains the responses returned by the block,
      # keyed by the exact request (using the object_id).
      # That way, there's no race condition in case #to_return
      # doesn't run immediately after stub.with.
      responses = {}

      stub = ::WebMock::RequestStub.new(:any, /.*/).with { |request|
        responses[request.object_id] = block.call(request)
      }.to_return(lambda { |request| responses.delete(request.object_id) })

      global_stubs.push stub
    end

    def register_request_stub(stub)
      request_stubs.insert(0, stub)
      stub
    end

    def registered_request?(request_signature)
      request_stub_for(request_signature)
    end

    def response_for_request(request_signature)
      stub = request_stub_for(request_signature)
      stub ? evaluate_response_for_request(stub.response, request_signature) : nil
    end

    private

    def request_stub_for(request_signature)
      (global_stubs + request_stubs).detect { |registered_request_stub|
        registered_request_stub.request_pattern.matches?(request_signature)
      }
    end

    def evaluate_response_for_request(response, request_signature)
      response.evaluate(request_signature)
    end

  end
end
