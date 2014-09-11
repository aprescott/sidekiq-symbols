Gem::Specification.new do |s|
  s.name         = "sidekiq-symbols"
  s.version      = "0.1.1"
  s.authors      = ["Adam Prescott"]
  s.email        = ["adam@aprescott.com"]
  s.homepage     = "https://github.com/aprescott/sidekiq-symbols"
  s.summary      = "Give Sidekiq symbols and keyword arguments."
  s.description  = "Forces Sidekiq jobs to use symbolized keys and enables keyword arguments."
  s.files        = Dir["{lib/**/*,spec/**/*,gemfiles/*.gemfile}"] + %w[sidekiq-symbols.gemspec LICENSE Gemfile Appraisals README.md]
  s.require_path = "lib"
  s.test_files   = Dir["spec/*"]
  s.required_ruby_version = ">= 2.0.0"
  s.licenses = ["MIT"]

  s.add_dependency("sidekiq")
  s.add_development_dependency("rspec", ">= 3.0")
  s.add_development_dependency("pry-byebug")
  s.add_development_dependency("appraisal")
end
