# encoding: utf-8

class Promptus::Rack::TokenAuthorization

  def initialize(app, key, token, options = {})
    @app = app
    @key = key
    @token = token
    @options = options
  end

  def call(env)
    req = Rack::Request.new(env)
    if req.path.start_with?("/admin") or req.path.start_with?("/assets")
      @app.call(env)
    elsif req.params[@key] != @token
      if @options[:content_type] == :json
        [403, { "Content-Type" => "application/json" }, [{ :staus => "forbidden", :message => "Invalid API key supplied." }.to_json]]
      else
        [403, { "Content-Type" => "text/plain" }, ['Forbidden']]
      end
    else
      @app.call(env)
    end
  end

end
