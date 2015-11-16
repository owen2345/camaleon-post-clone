$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "camaleon_post_clone/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "camaleon_post_clone"
  s.version     = CamaleonPostClone::VERSION
  s.authors     = ["Owen"]
  s.email       = ["owenperedo@gmail.com"]
  s.homepage    = ""
  s.summary     = ": Summary of CamaleonPostClone."
  s.description = ": Description of CamaleonPostClone."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails"
  s.add_dependency "deep_cloneable"

  s.add_development_dependency "sqlite3"
end
