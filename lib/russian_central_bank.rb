require 'money'
require 'savon'

class Money
  module Bank
    class RussianCentralBank < Money::Bank::VariableExchange

      CBR_SERVICE_URL = 'http://www.cbr.ru/DailyInfoWebServ/DailyInfo.asmx?WSDL'

      attr_reader :rates_updated_at, :rates_updated_on

      def flush_rates
        @mutex.synchronize{
          @rates = {}
        }
      end

      def update_rates(date = Date.today)
        @mutex.synchronize{
          update_parsed_rates exchange_rates(date)
          @rates_updated_at = Time.now
          @rates_updated_on = date
          @rates
        }
      end

      def set_rate(from, to, rate)
        @rates[rate_key_for(from, to)] = rate
      end

      def get_rate from, to
        @rates[rate_key_for(from, to)] || indirect_rate(from, to)
      end

      private

      def indirect_rate from, to
        from_base_rate = @rates[rate_key_for('RUB', from)]
        to_base_rate = @rates[rate_key_for('RUB', to)]
        to_base_rate / from_base_rate
      end

      def exchange_rates(date)
        client = Savon::Client.new(wsdl: CBR_SERVICE_URL)
        response = client.call(:get_curs_on_date, message: { 'On_date' => date.strftime('%Y-%m-%dT%H:%M:%S') })
        response.body[:get_curs_on_date_response][:get_curs_on_date_result][:diffgram][:valute_data][:valute_curs_on_date]
      end

      def update_parsed_rates rates
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
