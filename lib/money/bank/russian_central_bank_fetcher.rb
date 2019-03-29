require 'httparty'

class Money
  module Bank
    class RussianCentralBankFetcher
      DAILY_RATES_URL = 'http://www.cbr.ru/scripts/XML_daily.asp'.freeze

      class FetchError < StandardError
        attr_reader :response

        def initialize(message, response = nil)
          super(message)
          @response = response
        end
      end

      def perform(date = Date.today)
        response = HTTParty.get(rates_url(date))
        unless response.success?
          raise_fetch_error("cbr.ru respond with #{response.code}", response)
        end
        extract_rates(response.parsed_response)
      rescue HTTParty::Error => e
        raise_fetch_error(e.message)
      end

      private

      def raise_fetch_error(message, response = nil)
        raise FetchError.new(message, response)
      end

      def rates_url(date)
        "#{DAILY_RATES_URL}?date_req=#{date.strftime('%d/%m/%Y')}"
      end

      def extract_rates(parsed_response)
        rates_arr = parsed_response['ValCurs']['Valute']
        rates_arr.map do |rate|
          {
            code: rate['CharCode'],
            nominal: rate['Nominal'].to_i,
            value: rate['Value'].tr(',', '.').to_f
          }
        end
      end
    end
  end
end
