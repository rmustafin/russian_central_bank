require 'money'

class Money
  module Bank
    class RussianCentralBank < Money::Bank::VariableExchange
      attr_reader :rates_updated_at, :rates_updated_on, :rates_expired_at, :ttl

      def flush_rates
        @store = Money::RatesStore::Memory.new
      end

      def update_rates(date = Date.today)
        store.transaction do
          update_parsed_rates(exchange_rates(date))
          @rates_updated_at = Time.now
          @rates_updated_on = date
          update_expired_at
          store.send(:rates)
        end
      end

      def add_rate(from, to, rate)
        super(from, to, rate)
        super(to, from, 1.0 / rate)
      end

      def get_rate(from, to)
        update_rates if rates_expired?
        super || indirect_rate(from, to)
      end

      def ttl=(value)
        @ttl = value
        update_expired_at
        @ttl
      end

      def rates_expired?
        rates_expired_at && rates_expired_at <= Time.now
      end

      private

      def fetcher
        @fetcher ||= RussianCentralBankFetcher.new
      end

      def exchange_rates(date)
        fetcher.perform(date)
      end

      def update_expired_at
        @rates_expired_at = if ttl
          @rates_updated_at ? @rates_updated_at + ttl : Time.now
        else
          nil
        end
      end

      def indirect_rate(from, to)
        get_rate('RUB', to) / get_rate('RUB', from)
      end

      def local_currencies
        @local_currencies ||= Money::Currency.table.map { |currency| currency.last[:iso_code] }
      end

      def update_parsed_rates(rates)
        add_rate('RUB', 'RUB', 1)
        rates.each do |rate|
          begin
            if local_currencies.include?(rate[:code])
              add_rate(
                'RUB',
                rate[:code],
                1 / (rate[:value] / rate[:nominal])
              )
            end
          rescue Money::Currency::UnknownCurrency
          end
        end
      end
    end
  end
end
