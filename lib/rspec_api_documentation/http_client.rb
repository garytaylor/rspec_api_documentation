module RspecApiDocumentation
  class HttpClient < ClientBase

    delegate :last_request, :last_response, :to => :http_session
    private :last_request, :last_response

    def request_headers
      env_to_headers(last_request.env)
    end

    def response_headers
      last_response.headers
    end

    def query_string
      last_request.env["QUERY_STRING"]
    end

    def status
      last_response.status
    end

    def response_body
      last_response.body
    end

    def request_content_type
      last_request.content_type
    end

    def response_content_type
      last_response.content_type
    end

    protected

    def do_request(method, path, params, request_headers)
      http_session.send(method, path, params, headers(method, path, params, request_headers))
    end

    def headers(*args)
      headers_to_env(super)
    end

    def handle_multipart_body(request_headers, request_body)
      parsed_parameters = Rack::Request.new({
        "CONTENT_TYPE" => request_headers["Content-Type"],
        "rack.input" => StringIO.new(request_body)
      }).params

      clean_out_uploaded_data(parsed_parameters,request_body)
    end

    private

    def clean_out_uploaded_data(params,request_body)
      params.each do |_, value|
        if value.is_a?(Hash)
          if value.has_key?(:tempfile)
            data = value[:tempfile].read
            request_body = request_body.gsub(data, "[uploaded data]")
          else
            request_body = clean_out_uploaded_data(value,request_body)
          end
        end
      end
      request_body
    end

    def http_session
      @http_session ||= HttpSession.new()
    end
  end
end
