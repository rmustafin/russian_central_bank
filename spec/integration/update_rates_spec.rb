require 'spec_helper'

describe 'Update Rates' do
  let(:bank) { Money::Bank::RussianCentralBank.new }
  let(:rates_xml) { File.read('spec/support/rcb_response.xml') }
  let(:date) { Date.today }
  let(:rates_url) do
    "#{Money::Bank::RussianCentralBankFetcher::DAILY_RATES_URL}?date_req=#{date.strftime('%d/%m/%Y')}"
  end

  context 'when cbr.ru successfully returns rates' do
    before do
      stub_request(:get, rates_url).to_return(
        status: 200,
        body: rates_xml,
        headers: {
          "content-type"=>["application/xml; charset=windows-1251"]
        }
      )

      bank.update_rates
    end

    it 'adds rates', :aggregete_failure do
      expect(bank.get_rate('USD', 'RUB')).to eq(64.4993)
      expect(bank.get_rate('RUB', 'USD')).to eq(0.015504044229937378)
    end

    it 'adds rates for currencies with nominal > 1', :aggregete_failure do
      expect(bank.get_rate('DKK', 'RUB')).to eq(9.76581)
      expect(bank.get_rate('RUB', 'DKK')).to eq(0.10239806017114812)
    end
  end

  context 'when cbr.ru request fails' do
    before do
      stub_request(:get, rates_url).to_return(
        status: 503,
        body: '503'
      )
    end

    it 'raises FetchError' do
      expect { bank.update_rates }.to raise_error(Money::Bank::RussianCentralBankFetcher::FetchError)
    end
  end
end
