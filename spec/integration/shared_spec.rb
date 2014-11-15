# Shared spec for testing response headers

shared_examples_for 'with accept type' do
  HEADER_KEYS = [ 'Content-Type','Cache-Control', 'expires', 'X-UA-Compatible', 'ETag', 'X-Request-Id', 'X-Runtime', 'Content-Length' ]

  it 'contains the correct header keys' do
    HEADER_KEYS.each {|k| expect(response.headers.keys).to include(k)}
  end

  it 'contains accurate content-type' do
    expect(response.headers['content-type']).to eql(accept)
  end

  it 'contains accurate content-length' do
    expect(response.headers['content-length']).to eql(response.body.length.to_s)
  end
end