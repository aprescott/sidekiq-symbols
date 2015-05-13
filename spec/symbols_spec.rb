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

  def expect_transformation(klass, *input, arg_signature)
    klass.perform_async(*input)
    expect($find_a_better_way_than_this).to eq(arg_signature)
  end

  before do
    $find_a_better_way_than_this = nil
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

  describe "subclassing" do
    class SampleJobWithInheritedAfterInclude
      include Sidekiq::Symbols

      class <<self; attr_accessor :inherited_value; end

      def self.inherited(subclass)
        self.inherited_value = "original-inherited-value-after-include"
      end
    end

    class SampleJobWithInheritedBeforeInclude
      class <<self; attr_accessor :inherited_value; end

      def self.inherited(subclass)
        self.inherited_value = "original-inherited-value-before-include"
      end

      include Sidekiq::Symbols
    end

    class SubclassWithoutIncludeJob < SampleJob
      def perform(*args, **kwargs)
        $find_a_better_way_than_this = [args, kwargs]
      end
    end

    class SubclassFoo < SampleJobWithInheritedAfterInclude; end
    class SubclassBar < SampleJobWithInheritedBeforeInclude; end

    it "works with subclasses that don't include the module directly" do
      input = [1, "x" => { "y" => 2, z: { "foo bar" => 0 } }]
      arg_signature = [[1], { x: { y: 2, z: { :"foo bar" => 0 } } }]

      expect_transformation(SubclassWithoutIncludeJob, *input, arg_signature)
    end

    it "does not conflict with an existing self.inherited hook that appears after the include" do
      expect(SampleJobWithInheritedAfterInclude.inherited_value).to eq("original-inherited-value-after-include")
    end

    it "does not conflict with an existing self.inherited hook that appears before the include" do
      expect(SampleJobWithInheritedBeforeInclude.inherited_value).to eq("original-inherited-value-before-include")
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
