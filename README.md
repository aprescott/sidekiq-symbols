[![Build Status](https://travis-ci.org/aprescott/sidekiq-symbols.svg?branch=master)](https://travis-ci.org/aprescott/sidekiq-symbols)

sidekiq-symbols gives you symbol keys and Ruby keyword arguments for your Sidekiq jobs.

### Caveats

I have not tested this in a production environment! The 0.x version is there for a reason!

### To use

Include the `Sidekiq::Symbols` module in your job class:

```ruby
class SomeJob
  include Sidekiq::Worker
  include Sidekiq::Symbols

  # ...
end
```

### What it does

Consider this Sidekiq job:

```ruby
class SomeJob
  include Sidekiq::Worker

  def perform(opts = {})
    raise unless opts.has_key?(:x)
  end
end

# used as:

SomeJob.perform_async(x: 1)
```

Because Sidekiq round-trips job arguments through JSON serialization-deserialization, this job will raise as the arguments are converted from

```ruby
{ x: 1 }
```

to

```ruby
{ "x" => 1 }
```

and then passes it to `perform`. So it will end up being called as:

```ruby
perform("x" => 1)
```

sidekiq-symbols forces `perform` to work with symbols, not strings:

```ruby
class SomeJob
  include Sidekiq::Worker
  include Sidekiq::Symbols

  def perform(arg, opts = {})
    opts[:x] == 1 # this is true now!
  end
end

SomeJob.perform_async("foo", x: 1)
```

Note that this means you **cannot** use strings for this job! `perform_async("foo", "x" => 1)` here is converted to `perform("foo", x: 1)` because `Sidekiq::Symbols` is included.

### Keyword arguments

Ruby's keyword arguments are essentially an extension of using a symbol-keyed hash argument, so sidekiq-symbols also enables keyword arguments:

```ruby
class SomeJob
  include Sidekiq::Worker
  include Sidekiq::Symbols

  def perform(x: 1, y: 2)
    # x and y are available
  end
end
```
