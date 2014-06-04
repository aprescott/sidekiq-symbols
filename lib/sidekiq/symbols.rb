require "sidekiq"

module Sidekiq
module Symbols
  def self.included(klass)
    klass.prepend(Symbolizer)
  end

  module Symbolizer
    def perform(*args)
      symbolized_args = args.map do |arg|
        if arg.is_a?(Hash)
          __sidekiq_symbols_symbolize_keys(arg)
        else
          arg
        end
      end.to_a
      super(*symbolized_args)
    end

    private

    def __sidekiq_symbols_symbolize_keys(arg)
      h = {}
      arg.each do |k, v|
        k = k.to_sym if k.respond_to?(:to_sym)
        h[k] = v.is_a?(Hash) ? __sidekiq_symbols_symbolize_keys(v) : v
      end
      h
    end
  end
end
end
