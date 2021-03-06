$:.push File.expand_path("../lib", __FILE__)

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "maturate"
  s.version     = "0.0.2"
  s.authors     = ["Todd Willey <todd.willey@cirrusmio.com>"]
  s.homepage    = "https://github.com/xtoddx/maturate"
  s.summary     = "Mature your rails API through sane versioning."
  s.description = "Update your API endpoints with minimal duplication. Uses variants for view enhancements, helper methods make the api_version easily accessable, offers a \"current\" named version, and defaults unknown versions to current. Tries very hard to support a array of clients and make sure everything works."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2"

  s.add_development_dependency "sqlite3"
end
