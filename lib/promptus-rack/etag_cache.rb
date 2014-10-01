# encoding: utf-8

class Promptus::Rack::ETagCache
  
  IF_NONE_MATCH_HEADER = 'HTTP_IF_NONE_MATCH'
  ETAG_HEADER = 'ETag'
  
  def initialize(app, hash_method = Digest::SHA1.new)
    @app = app
    @hash_method = hash_method
  end

  def call(env)
    status, headers, body = @app.call(env)
    if (200..206) === status
      old_checksum = env[IF_NONE_MATCH_HEADER]
      new_checksum = body.first ? "W/\"#{@hash_method.hexdigest(body.first)}\"" : nil
      if old_checksum == new_checksum && old_checksum
        [304, { }, ['']]
      else
        headers[ETAG_HEADER] = new_checksum if new_checksum
        [status, headers, body]
      end
    else
      res
    end

  end
  
end
