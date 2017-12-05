RSpec.describe Sidekiq::Symbols, sidekiq: :inline do
  class SampleJob
    include Sidekiq::Worker
    include Sidekiq::Symbols

    def perform(*args, **kwargs)
      $perform_arg_signature = [args, kwargs]
    end
  end

  class SampleHashArgJob
    include Sidekiq::Worker
    include Sidekiq::Symbols

    def perform(x, opts = {})
      $perform_arg_signature = [x, opts]
    end
  end

  def expect_transformation(klass, *input, arg_signature)
    klass.perform_async(*input)
    expect($perform_arg_signature).to eq(arg_signature)
  end

  before do
    $perform_arg_signature = nil
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

  it "symbolizes hashes inside arrays" do
    expect_transformation(SampleHashArgJob, 1, { "x" => [ { "y" => 2 } ] }, [1, x: [{y:2}]])
  end

  it "symbolizes hashes inside arrays inside hashes inside arrays" do
    input = [1, {"x" => [ { "y" => [ { "z" => 3 } ]  } ] }]
    arg_signature = [1, { x: [ { y: [ { z: 3 } ] } ] }]
    expect_transformation(SampleHashArgJob, *input, arg_signature)
  end

  it "symbolizes hashes inside arrays inside arrays" do
    input = [1, {"x" => [ [ { "y" => 2 }, { "z" => 3 } ] ] }]
    arg_signature = [1, { x: [ [ { y: 2 }, { z: 3 } ] ] }]
    expect_transformation(SampleHashArgJob, *input, arg_signature)

  end

  it "symbolizes all arguments to Sidekiq's perform" do
    input = [1, "x" => { "y" => 2, z: { "foo bar" => 0 } }]
    arg_signature = [[1], { x: { y: 2, z: { :"foo bar" => 0 } } }]

    expect_transformation(SampleJob, *input, arg_signature)
  end

  describe "subclassing" do
    class BaseJob
      include Sidekiq::Worker
    end

    class SubclassFooJob < BaseJob
      include Sidekiq::Symbols

      def perform(x: -1)
        $subclass_x = x
      end
    end

    class SubclassBarJob < BaseJob
      include Sidekiq::Symbols

      def perform(y: -1)
        $subclass_y = y
      end
    end

    it "works on subclasses that do their own include" do
      SubclassFooJob.perform_async(x: 1)
      SubclassBarJob.perform_async(y: 2)

      expect($subclass_x).to eq(1)
      expect($subclass_y).to eq(2)
    end
  end

  # 2.1+ introduced required keyword arguments, so this must be done with
  # eval to sidestep syntax errors at parse time.
  if RUBY_VERSION >= "2.1.0"
    # Note that this test is asserting that perform_async raises, but in
    # reality it will actually raise at the Sidekiq server level when the worker
    # tries to perform the job.
    #
    # perform_async itself won't raise because of missing required keyword args
    # in actual code.
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
