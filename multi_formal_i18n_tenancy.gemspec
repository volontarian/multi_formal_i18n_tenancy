$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'multi_formal_i18n_tenancy/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'multi_formal_i18n_tenancy'
  s.version     = MultiFormalI18nTenancy::VERSION
  s.authors     = ['Mathias Gawlista']
  s.email       = ['gawlista@googlemail.com']
  s.homepage    = 'http://applicat.github.com/multi_formal_i18n_tenancy'
  s.summary     = 'Your formal locales will inherit translations from their base locale and locales stored in an enterprise folder can override base + formal translations'
  s.description = 'Your formal locales will inherit translations from their base locale and locales stored in an enterprise folder can override base + formal translations'

  s.files = Dir['{app,config,db,lib}/**/*'] + ['MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['spec/**/*']
   
  # only needed for String#parameterize and Hash#deep_merge otherwise we would only need i18n
  s.add_dependency 'activesupport'

  # testing dependencies
  s.add_development_dependency('rspec', "~> #{'2.11.0'.split('.')[0..1].concat(['0']).join('.')}")
end
