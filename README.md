# RussianCentralBank

This gem extends Money::Bank::VariableExchange with Money::Bank::RussianCentralBank and gives acceess to the Central Bank of Russia currency exchange.

## Installation

Add this line to your application's Gemfile:

    gem 'russian_central_bank'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install russian_central_bank

##Dependencies

* savon
* money

## Usage

    bank = Money::Bank::RussianCentralBank

    # Load rates
    bank.update_rates

    Money.default_bank = bank

    # Exchange 100 USD to RUB
    100.to_money('USD').exchange_to('RUB')

    # Check last rates update
    bank.rates_updated_at

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
