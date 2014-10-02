require 'spec_helper'

class AppProxy
  
  def call(env)
    env[:response]
  end
  
end

describe ETagCache do
  
  before do
    @request = { :response => [200, {}, ['body']] }
    @cache = ETagCache.new(AppProxy.new)
  end
  
  it 'should add the ETag header' do
    status, headers, body = @cache.call(@request)
    expect(headers['ETag']).to match(/W\/"\w+"/)
  end
  
  it 'should not change the ETag header if there already is an ETag header set' do
    @request[:response][1]['ETag'] = 'W/"1234"'
    status, headers, body = @cache.call(@request)
    expect(headers['ETag']).to match(/W\/"1234"/)
  end
  
  it 'should add the default Cache-Control header' do
    status, headers, body = @cache.call(@request)
    expect(headers['Cache-Control']).to match(ETagCache::DEFAULT_CACHE_CONTROL)
  end
  
  it 'should not change an existing Cache-Control header' do
    @request[:response][1]['Cache-Control'] = 'public'
    status, headers, body = @cache.call(@request)
    expect(headers['Cache-Control']).to match('public')
  end
  
  it 'should not add an ETag if the status is 301' do
    @request[:response][0] = 301
    status, headers, body = @cache.call(@request)
    expect(headers['ETag']).to be_nil
  end
  
  context 'matching IF_NONE_MATCH header' do
    
    before do
      @request["HTTP_IF_NONE_MATCH"] = 'W/"02083f4579e08a612425c0c1a17ee47add783b94"'
    end
    
    it 'should return 304' do
      status, headers, body = @cache.call(@request)
      expect(status).to eql(304)
    end
    
    it 'should return an empty body' do
      status, headers, body = @cache.call(@request)
      expect(body).to eql([''])
    end
    
  end
  
  context 'mismatching IF_NONE_MATCH header' do
    
    before do
      @request["HTTP_IF_NONE_MATCH"] = 'W/"02083f4579e08a612425c0c1a17ee47add783b95"'
    end
    
    it 'should return 200 status if the ETag does not match the IF_NONE_MATCH header' do
      status, headers, body = @cache.call(@request)
      expect(status).to eql(200)
    end
  
  end
  
end
