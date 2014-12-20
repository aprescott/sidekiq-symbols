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
end

# sidekiq test configuration
RSpec.configure do |config|
  config.before(:each) do |example_method|
    # Clears out the jobs for tests using the fake testing
    Sidekiq::Worker.clear_all
  end

  # use an around to allow each test to specify
  # its own around block and override the testing
  # context.
  config.around(:each) do |example|
    # acceptance tests run the jobs immediately.
    if example.metadata[:type] == :feature || example.metadata[:sidekiq] == :inline
      Sidekiq::Testing.inline!(&example)
    else
      Sidekiq::Testing.fake!(&example)
    end
  end
end
