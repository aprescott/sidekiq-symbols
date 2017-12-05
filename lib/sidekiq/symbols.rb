require "sidekiq"

module Sidekiq
module Symbols
  def self.included(klass)
    klass.class_eval { prepend(Symbolizer) }
  end

  module Symbolizer
    def perform(*args)
      symbolized_args = args.map do |arg|
        if __sidekiq_symbols_should_process?(arg)
          __sidekiq_symbols_symbolize_keys(arg)
        else
          arg
        end
      end.to_a
      super(*symbolized_args)
    end

    private

    def __sidekiq_symbols_symbolize_keys(arg)
      case arg
      when Hash
        h = {}
        arg.each do |k, v|
          k = k.to_sym if k.respond_to?(:to_sym)
          h[k] = __sidekiq_symbols_should_process?(v) ? __sidekiq_symbols_symbolize_keys(v) : v
        end
        h
      when Array
        arg.map { |v| __sidekiq_symbols_should_process?(v) ? __sidekiq_symbols_symbolize_keys(v) : v }
      else
        arg
      end
    end

    def __sidekiq_symbols_should_process?(arg)
      arg.is_a?(Hash) || arg.is_a?(Array)
    end
  end
end
end
