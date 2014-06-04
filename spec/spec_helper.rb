require "bundler/setup"
require "sidekiq/symbols"
require "sidekiq/testing"
require "pry-byebug"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  if config.files_to_run.one?
    config.full_backtrace = true
  end

  config.around(:each) do |example|
    Sidekiq::Testing.inline!(&example)
  end
end
