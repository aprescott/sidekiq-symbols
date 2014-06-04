Gem::Specification.new do |s|
  s.name         = "sidekiq-symbols"
  s.version      = "0.1"
  s.authors      = ["Adam Prescott"]
  s.email        = ["adam@aprescott.com"]
  s.homepage     = ""
  s.summary      = "Symbolize your Sidekiq jobs."
  s.description  = "Symbolize your Sidekiq jobs."
  s.files        = Dir["{lib/**/*,spec/**/*}"] + %w[sidekiq-symbols.gemspec LICENSE Gemfile README.md]
  s.require_path = "lib"
  s.test_files   = Dir["spec/*"]
  s.required_ruby_version = ">= 1.9.3"
  s.licenses = ["MIT"]

  #s.add_dependency("sidekiq")
  #s.add_development_dependency("rspec", ">= 3.0")
  #s.add_development_dependency("pry-byebug")
end
