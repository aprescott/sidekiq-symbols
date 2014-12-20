require "spec_helper"

RSpec.describe Sidekiq::Symbols, sidekiq: :inline do
  class SampleJob
    include Sidekiq::Worker
    include Sidekiq::Symbols

    def perform(*args, **kwargs)
      $find_a_better_way_than_this = [args, kwargs]
    end
  end

  class SampleHashArgJob
    include Sidekiq::Worker
    include Sidekiq::Symbols

    def perform(x, opts = {})
      $find_a_better_way_than_this = [x, opts]
    end
  end

  # used to verify that the `include` on the parent carries
  # through to the subclass even if the subclass doesn't
  # `include` the module itself.
  class SubclassWithoutIncludeJob < SampleJob
    def perform(*args, **kwargs)
      $find_a_better_way_than_this = [args, kwargs]
    end
  end

  def expect_transformation(klass, *input, arg_signature)
    klass.perform_async(*input)
    expect($find_a_better_way_than_this).to eq(arg_signature)
  end

  it "allows regular arguments" do
    expect_transformation(SampleJob, 1, [[1], {}])
  end

  it "allows keyword args" do
    expect_transformation(SampleJob, { x: 1 }, [[], x: 1])
  end

  it "symbolizes old-style hash args" do
    expect_transformation(SampleHashArgJob, 1, { "x" => 1 }, [1, x: 1])
  end

  it "symbolizes all arguments to Sidekiq's perform" do
    input = [1, "x" => { "y" => 2, z: { "foo bar" => 0 } }]
    arg_signature = [[1], { x: { y: 2, z: { :"foo bar" => 0 } } }]

    expect_transformation(SampleJob, *input, arg_signature)
  end

  it "works with subclasses that don't include the module directly" do
    input = [1, "x" => { "y" => 2, z: { "foo bar" => 0 } }]
    arg_signature = [[1], { x: { y: 2, z: { :"foo bar" => 0 } } }]

    expect_transformation(SubclassWithoutIncludeJob, *input, arg_signature)
  end

  if RUBY_VERSION >= "2.1.0"
    # not that this test asserts that perform_async raises, but
    # in reality it will raise at the Sidekiq server level when
    # the worker tries to perform the job, not at the client
    # call site for perform_async.
    eval <<-DEFEAT_THE_PARSER
      class SampleRequiredKeywordArgsJob
        include Sidekiq::Worker
        include Sidekiq::Symbols

        def perform(x:)
        end
      end

      it "raises on missing required keyword args" do
        expect { SampleRequiredKeywordArgsJob.perform_async }.to raise_error(ArgumentError)
      end
    DEFEAT_THE_PARSER
  end
end
