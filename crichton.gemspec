$LOAD_PATH.unshift 'lib'
require 'crichton/version'

Gem::Specification.new do |s|
  s.name          = 'crichton'
  s.version       = Crichton::VERSION::STRING
  s.date          = Time.now.strftime('%Y-%m-%d')
  s.summary       = 'It has the knowledge of Hypermedia from the Ancients!'
  s.homepage      = 'http://github.com//crichton'
  s.email         = ''
  s.authors       = ['Mark W. Foster']
  s.files         = ['lib/**/*', 'spec/**/*', 'tasks/**/*', '[A-Z]*'].map { |glob| Dir[glob] }.inject([], &:+)
  s.require_paths = ['lib']
  s.rdoc_options  = ['--main', 'README.md']
  s.executables   = ['rdlint']

  s.description   = <<-DESC
    Crichton is a library to simplify generating and consuming Hypermedia API responses.
  DESC

  s.add_dependency('rake')
  s.add_dependency('activesupport', '~> 3.2.0')
  s.add_dependency('addressable',   '~> 2.3.0')
  s.add_dependency('builder',       '~> 3.0.0')
  s.add_dependency('dice_bag',      '~> 0.7.0')
  s.add_dependency('diffy')
end
