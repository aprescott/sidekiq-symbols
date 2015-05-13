require "sidekiq"

module Sidekiq
module Symbols
  def self.symbolize_args(args)
    symbolize_keys = lambda do |arg|
      h = {}
      arg.each do |k, v|
        k = k.to_sym if k.respond_to?(:to_sym)
        h[k] = v.is_a?(Hash) ? symbolize_keys.call(v) : v
      end
      h
    end

    symbolized_args = args.map do |arg|
      if arg.is_a?(Hash)
        symbolize_keys.call(arg)
      else
        arg
      end
    end.to_a
  end

  def self.included(klass)
    klass.class_eval { prepend(Symbolizer) }

    # Avoid trampling on an existing `inherited` definition.
    class <<klass
      prepend(Module.new {
        def inherited(subclass)
          subclass.class_eval { prepend(SubclassSymbolizer) }
          super
        end
      })
    end
  end

  module Symbolizer
    def perform(*args)
      super(*Sidekiq::Symbols.symbolize_args(args))
    end
  end

  module SubclassSymbolizer
    def perform(*args)
      super(*Sidekiq::Symbols.symbolize_args(args))
    end
  end
end
end
