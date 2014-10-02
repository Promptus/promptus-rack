# encoding: utf-8

class Promptus::Rack::ETagCache
  
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
      old_checksum = env[IF_NONE_MATCH_KEY]
      new_checksum = body.first ? "W/\"#{@hash_method.hexdigest(body.first)}\"" : nil
      if old_checksum && old_checksum == new_checksum
        return [304, {}, ['']]
      elsif new_checksum
        headers[ETAG_HEADER] = new_checksum
        headers[CACHE_CONTROL_HEADER] = DEFAULT_CACHE_CONTROL if headers[CACHE_CONTROL_HEADER].nil?
      end
    end
    [status, headers, body]
  end
  
  private
  
  def etag_present?(headers)
    !(headers[ETAG_HEADER].nil? || headers[ETAG_HEADER] == '')
  end
  
end
