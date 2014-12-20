require "sidekiq"

module Sidekiq
module Symbols
  def self.included(klass)
    def klass.execute_job(worker, args)
      symbolized_args = args.map do |arg|
        if arg.is_a?(Hash)
          Sidekiq::Symbols.__symbolize_keys(arg)
        else
          arg
        end
      end.to_a

      worker.perform(*symbolized_args)
    end
  end

  def self.__symbolize_keys(arg)
    h = {}
    arg.each do |k, v|
      k = k.to_sym if k.respond_to?(:to_sym)
      h[k] = v.is_a?(Hash) ? Sidekiq::Symbols.__symbolize_keys(v) : v
    end
    h
  end
end
end
