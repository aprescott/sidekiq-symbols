sidekiq-symbols gives you symbol keys for your `perform` method.

### Caveats

I have not tested this in a production environment! The 0.x version is there for a reason!

### To use

Add

```ruby
include Sidekiq::Symbols
```

to your Sidekiq job class.

```ruby
class SomeJob
  include Sidekiq::Worker
  include Sidekiq::Symbols

  # ...
end
```

### What it does

Because Sidekiq round-trips job arguments through JSON serialization-deserialization, a hash argument passed to `perform_async` which uses symbols won't actually be `fetch`able with symbol keys, because

```ruby
perform_async(x: 1)
```

leads to when it gets pulled out of Redis.

```ruby
perform("x" => 1)
```

sidekiq-symbols forces `perform` to use symbols for all its keys, so that this works:

```ruby
class SomeJob
  include Sidekiq::Worker
  include Sidekiq::Symbols

  def perform(arg, opts = {})
    opts[:x] # this works
  end
end

SomeJob.perform_async("foo", x: 1)
```

Note that `perform_async("foo", "x" => 1)` here would leave `opts["x"] == nil` since you _must_ use `opts[:x]`.

### Keyword arguments

Ruby's keyword arguments are essentially an extension of using a symbol-keyed hash argument, so sidekiq-symbols also enables keyword arguments:

```ruby
class SomeJob
  include Sidekiq::Worker
  include Sidekiq::Symbols

  def perform(x: 1, y: 2)
    # x and y are availalbe
  end
end
```
