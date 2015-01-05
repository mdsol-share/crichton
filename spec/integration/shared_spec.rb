# Shared spec for testing response headers

shared_examples_for 'a response with well formed headers' do

  # TODO: Include test for link headers when implemented
  # TODO: Moya is not including expires headers in all responses, determine appropriate behavior
  HEADER_KEYS = [ 'content-type',
                  'cache-control',
                  'etag',
                  'x-request-id',
                  'x-runtime',
                  'content-length'
                ]

  it 'contains the correct header keys' do
    HEADER_KEYS.each {|k| expect(response.headers.keys).to include(k)}
  end


  # TODO: Fix moya, it is returning a */* Content-Type
  xit 'contains accurate content-type' do
    expect(response.headers['content-type']).to eql(accept)
  end

  it 'contains accurate content-length' do
    expect(response.headers['content-length']).to eql(response.body.length.to_s)
  end

  it 'contains accurate link headers' do
    pending('this is pending on implementing link headers')
    expect(response.headers['link']).to eql(link)
  end
end
