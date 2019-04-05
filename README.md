[![Build Status](https://circleci.com/gh/rmustafin/russian_central_bank.svg?style=shield)](https://circleci.com/gh/rmustafin/russian_central_bank)
[![License](https://img.shields.io/github/license/rmustafin/russian_central_bank.svg)](http://opensource.org/licenses/MIT)

# RussianCentralBank

This gem provides access to the Central Bank of Russia currency exchange. It can be used as a standalone exchange rates parser and also extends [Money](https://github.com/RubyMoney/money)::Bank::VariableExchange with [Money](https://github.com/RubyMoney/money)::Bank::RussianCentralBank

## Installation

Add this line to your application's Gemfile:

    gem 'russian_central_bank'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install russian_central_bank

NOTE: use 0.x version of `russian_central_bank` for `money` versions < 6.0 

## Dependencies

* [httparty](https://github.com/jnunemaker/httparty)
* [money](https://github.com/RubyMoney/money)

## Usage

### Standalone currency rates provider

```ruby
require 'russian_central_bank'

# Today rates
Money::Bank::RussianCentralBankFetcher.new.perform()
# => [{:code=>"USD", :nominal=>1, :value=>65.1639}, ...]

# For any other date
Money::Bank::RussianCentralBankFetcher.new.perform(Date.new(2010, 12, 31))
# => [{:code=>"USD", :nominal=>1, :value=>30.4769}, ...]
```

### Regular usage (with money gem)

```ruby
require 'russian_central_bank'

Money.locale_backend = :currency
bank = Money::Bank::RussianCentralBank.new

Money.default_bank = bank

# Load today's rates
bank.update_rates

# Exchange 1000 USD to RUB
Money.new(1000_00, "USD").exchange_to('RUB').format  # => 64.592,50 ₽

# Use indirect exchange rates, USD -> RUB -> EUR
Money.new(1000_00, "USD").exchange_to('EUR').format  # => €888,26
```

### Specific date rates

```ruby
# Specify rates date
bank.update_rates(Date.new(2010, 12, 31))
Money.new(1000_00, "USD").exchange_to('RUB').format  # => 30.476,90 ₽

# Check last rates update
bank.rates_updated_at

# Check on which date rates were updated
bank.rates_updated_on
```

### Autoupdate

```ruby
# Use ttl attribute to enable rates autoupdate
bank.ttl = 1.day

# Check expiration date
bank.rates_expired_at
```

### Safe rates fetch

There are some cases, when the `cbr.ru` doesn't return HTTP 200.
To avoid issues in production, you use fallback:

```ruby
bank = Money::Bank::RussianCentralBank.new
begin
  bank.update_rates
rescue Money::Bank::RussianCentralBankFetcher::FetchError => e
  Rails.logger.info "CBR failed: #{e.response}"

  ## fallback
  Money.default_bank = Money::Bank::VariableExchange.new

  Money.default_bank.add_rate(:usd, :eur, 1.3)
  Money.default_bank.add_rate(:eur, :usd, 0.7)
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
