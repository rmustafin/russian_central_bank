[![Build Status](https://circleci.com/gh/rmustafin/russian_central_bank.svg?style=shield)](https://circleci.com/gh/rmustafin/russian_central_bank)
[![License](https://img.shields.io/github/license/rmustafin/russian_central_bank.svg)](http://opensource.org/licenses/MIT)

# RussianCentralBank

This gem extends [Money](https://github.com/RubyMoney/money)::Bank::VariableExchange with [Money](https://github.com/RubyMoney/money)::Bank::RussianCentralBank and gives access to the Central Bank of Russia currency exchange.

## Installation

Add this line to your application's Gemfile:

    gem 'russian_central_bank'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install russian_central_bank

NOTE: use 0.x version of `russian_central_bank` for > 6.0 `money` versions

##Dependencies

* [savon](http://savonrb.com/)
* [money](https://github.com/RubyMoney/money)

## Usage

Regular usage

    require 'russian_central_bank'

    bank = Money::Bank::RussianCentralBank.new

    Money.default_bank = bank

    # Load today's rates
    bank.update_rates

    # Exchange 100 USD to RUB
    Money.new(1000, "USD").exchange_to('RUB')

Specific date rates

    # Specify rates date
    bank.update_rates(Date.today - 3000)
    Money.new(1000, "USD").exchange_to('RUB')  # makes you feel better

    # Check last rates update
    bank.rates_updated_at

    # Check on which date rates were updated
    bank.rates_updated_on

Autoupdate

    # Use ttl attribute to enable rates autoupdate
    bank.ttl = 1.day

    # Check expiration date
    bank.rates_expired_at

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
