# encoding: utf-8

class Promptus::Rack::ETag
  
  IF_NONE_MATCH_KEY     = 'HTTP_IF_NONE_MATCH'.freeze
  ETAG_HEADER           = 'ETag'.freeze
  CACHE_CONTROL_HEADER  = 'Cache-Control'.freeze
  DEFAULT_CACHE_CONTROL = "max-age=0, private, must-revalidate".freeze
  
  def initialize(app, hash_method = Digest::SHA1.new)
    @app = app
    @hash_method = hash_method
  end

  def call(env)
    status, headers, body = @app.call(env)
    if (200..206) === status && !etag_present?(headers)
      old_etag = env[IF_NONE_MATCH_KEY]
      digest = digest_body(body)
      new_etag = "W/\"#{digest}\"" if digest
      if old_etag && new_etag && old_etag == new_etag
        return [304, {}, []]
      elsif new_etag
        headers[ETAG_HEADER] = new_etag
        headers[CACHE_CONTROL_HEADER] = DEFAULT_CACHE_CONTROL if headers[CACHE_CONTROL_HEADER].nil?
      end
    end
    [status, headers, body]
  end
  
  private
  
  def etag_present?(headers)
    !(headers[ETAG_HEADER].nil? || headers[ETAG_HEADER] == '')
  end
  
  def digest_body(body)
    string_body = ''
    body.each do |part|
      string_body += part.to_s unless part.nil?
    end
    string_body.empty? ? nil : @hash_method.hexdigest(string_body)
  end
  
end
