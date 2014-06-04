require "spec_helper"

describe Sidekiq::Symbols do
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

  def expect_transformation(klass, *input, arg_signature)
    expect(klass.new.perform(*input)).to eq(arg_signature)
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
end
