require 'money'
require 'savon'

class Money
  module Bank
    class RussianCentralBank < Money::Bank::VariableExchange

      CBR_SERVICE_URL = 'http://www.cbr.ru/DailyInfoWebServ/DailyInfo.asmx?WSDL'

      attr_reader :rates_updated_at, :rates_updated_on, :ttl, :rates_expired_at

      def flush_rates
        @store = Money::RatesStore::Memory.new
      end

      def update_rates(date = Date.today)
        store.transaction do
          update_parsed_rates(exchange_rates(date))
          @rates_updated_at = Time.now
          @rates_updated_on = date
          update_expired_at
          store.send(:index)
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

      def update_expired_at
        @rates_expired_at = if ttl
          @rates_updated_at ? @rates_updated_at + ttl : Time.now
        else
          nil
        end
      end

      def indirect_rate(from, to)
        from_base_rate = get_rate('RUB', from)
        to_base_rate = get_rate('RUB', to)
        to_base_rate / from_base_rate
      end

      def exchange_rates(date = Date.today)
        client = Savon::Client.new wsdl: CBR_SERVICE_URL, log: false, log_level: :error,
          follow_redirects: true
        response = client.call(:get_curs_on_date, message: { 'On_date' => date.strftime('%Y-%m-%dT%H:%M:%S') })
        response.body[:get_curs_on_date_response][:get_curs_on_date_result][:diffgram][:valute_data][:valute_curs_on_date]
      end

      def update_parsed_rates(rates)
        local_currencies = Money::Currency.table.map { |currency| currency.last[:iso_code] }
        add_rate('RUB', 'RUB', 1)
        rates.each do |rate|
          begin
            if local_currencies.include? rate[:vch_code]
              add_rate('RUB', rate[:vch_code], 1/ (rate[:vcurs].to_f / rate[:vnom].to_i))
            end
          rescue Money::Currency::UnknownCurrency
          end
        end
      end
    end
  end
end
