# sidekiq-symbols

[![Build Status](https://travis-ci.org/aprescott/sidekiq-symbols.svg?branch=master)](https://travis-ci.org/aprescott/sidekiq-symbols)

sidekiq-symbols gives you symbol keys and Ruby keyword arguments for your Sidekiq jobs.

### License

Copyright (c) 2014 Adam Prescott, licensed under the MIT license. See LICENSE.

### Caveats

I have not tested this in a production environment! The 0.x version is there for a reason!

### Installing

With Bundler:

```ruby
# in Gemfile
gem "sidekiq-symbols"
```

Either `require "sidekiq-symbols"` or `require "sidekiq/symbols"`.

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

### Development

Issues (bugs, questions, etc.) should be opened with [the GitHub project](https://github.com/aprescott/sidekiq-symbols).

To contribute changes:

1. Visit the [GitHub repository for `sidekiq-symbols`](https://github.com/aprescott/sidekiq-symbols).
2. [Fork the repository](https://help.github.com/articles/fork-a-repo).
3. Make new feature branch: `git checkout -b master new-feature` (do not add on top of `master`!)
4. Implement the feature, along with tests.
5. [Send a pull request](https://help.github.com/articles/fork-a-repo).

Tests live in `spec/`. Run them with `rspec`.
