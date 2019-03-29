require 'spec_helper'

describe Money::Bank::RussianCentralBankFetcher do
  describe 'perform' do
    subject(:perform) { fetcher.perform(date) }

    let(:date) { Date.today }
    let(:fetcher) { described_class.new }
    let(:rates_url) do
      "http://www.cbr.ru/scripts/XML_daily.asp?date_req=#{date.strftime('%d/%m/%Y')}"
    end

    context 'when RCB responds' do
      let(:rcb_response) do
        instance_double(
          'response',
          parsed_response: parsed_response,
          success?: response_is_success,
          code: response_code
        )
      end
      let(:parsed_response) do
        {
          'ValCurs' => {
            'Valute' => [
              {
                'CharCode' => 'XXX',
                'Nominal' => '1',
                'Value' => '100,1'
              }
            ]
          }
        }
      end

      before do
        allow(HTTParty).to receive(:get).with(rates_url).and_return(rcb_response)
      end

      context 'and respond is successfull' do
        let(:response_is_success) { true }
        let(:response_code) { 200 }

        it 'returns a normalized array of rates' do
          expect(perform).to eq(
            [
              {
                code: 'XXX', nominal: 1, value: 100.1
              }
            ]
          )
        end
      end

      context 'and repsond is not successfull' do
        let(:response_is_success) { false }
        let(:response_code) { 503 }

        it 'raises FetchError' do
          expect { perform }.to raise_error(Money::Bank::RussianCentralBankFetcher::FetchError)
        end
      end
    end

    context 'when RCB fails to respond' do
      let(:error_message) { 'RCB failed to response' }

      before do
        allow(HTTParty).to receive(:get).with(rates_url).and_raise(HTTParty::Error, error_message)
      end

      it 'rescues an exception and raises FetchError' do
        expect { perform }.to raise_error(Money::Bank::RussianCentralBankFetcher::FetchError, error_message)
      end
    end
  end
end
