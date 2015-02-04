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

    # if for some path you want to not validate the api key
    # e.g. except => ["/admin", "assets"]
    
    skip = false
    if @options[:except]
      @options[:except].each do |exception|
        skip = true if req.path.start_with?(exception)
      end
    end

    if skip
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
