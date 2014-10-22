require 'rake'

load 'Rakefile'


def random_text(datum)
  if datum['pattern']
    maxlength = datum['maxlength'] || '50'
    len_elem = datum['pattern'].scan('*').size + datum['pattern'].scan('+').size
    sub_size = maxlength.to_i / len_elem.to_i
    pattern = datum['pattern'].gsub('.', '\w').gsub('+', "{1,#{sub_size}}").gsub('*', "{0,#{sub_size}}")
    Regexp.new(pattern).gen
  else
    rand(36**(datum['maxlength'] || 10)).to_s(36)
  end
end

def random_by_type(datum)
  type_generator = {
    "bool" => lambda { |x| [true, false].sample },
    "text" => lambda { |x| random_text(x) },
    "number"=> lambda { |x| Random.rand((x['min'] || 0)...(x['max'] || 100)) }, # should be integer in descriptor file
    }
  type = datum['type'].split(':')[0]
  type_generator[type].call(datum)
end

def random_by_datum(datum)
  options = datum.fetch('options', [])
  options = options.is_a?(Hash) ? options.values : options
  options = options.empty? ? datum['type'] : options
  options = options == 'text:select' ? nil : options # Fix when CR integrated, problem with _meta
  options.is_a?(Array) ? options.sample : random_by_type(datum)
end

def call_rspec_rails_by_media_method(method, href, data, media)
  calls = {
    'POST' => lambda { |href, data, media| post href, data, media },
    'GET' => lambda { |href, data, media| get href, data, media },
    'PUT' => lambda { |href, data, media| put href, data, media },
    'DELETE' => lambda { |href, data, media| delete href, data, media },
    }
  calls[method].call(href, data, media)
  response
end

def _http_call(link_object, data, default_media)
  method = (link_object['method'] || 'get').upcase
  href = link_object['href']
  media = link_object["enctype"] || default_media
  media = media.is_a?(Array) ? media.sample : media
  call_rspec_rails_by_media_method(method, href, data, media)
end

def hale_request(object, link_relation, options = {})
  _http_call object['_links'][link_relation], options, {'HTTP_ACCEPT' => 'application/vnd.hale+json'}
end