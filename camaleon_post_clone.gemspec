# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'camaleon_post_clone/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'camaleon_post_clone'
  s.version     = CamaleonPostClone::VERSION
  s.authors     = ['Owen Peredo']
  s.email       = ['owenperedo@gmail.com']
  s.homepage    = 'https://github.com/owen2345/camaleon-post-clone'
  s.summary     = 'Post clone plugin for Camaleon CMS'
  s.description = 'Clone a Camaleon CMS post from its editor, with its categories, tags, metas and, optionally, ' \
                  'its custom field values, saved as a published or a pending copy.'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 3.0'

  # No test_files: RubyGems merges it into `files`, which would ship the test suite to users.
  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  s.add_dependency 'deep_cloneable'
  s.add_dependency 'rails'
end
