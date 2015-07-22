require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'RussianCentralBank' do
  before do
    rates_hash = symbolize_keys YAML::load(File.open('spec/support/daily_rates.yml'))
    allow(Savon::Client).to receive_message_chain(:call, :body => rates_hash)
  end

  before :each do
    @bank = Money::Bank::RussianCentralBank.new
  end

  describe '#update_rates' do
    before do
      @bank.update_rates
    end

    it 'should update rates from daily rates service' do
      @bank.rates['RUB_TO_USD'].should == 0.03083678705348332
      @bank.rates['RUB_TO_EUR'].should == 0.023478587528174305
      @bank.rates['RUB_TO_JPY'].should == 3.086143524190736
    end
  end

  describe '#flush_rates' do
    before do
      @bank.add_rate('RUB', 'USD', 0.03)
    end

    it 'should delete all rates' do
      @bank.get_rate('RUB', 'USD')
      @bank.flush_rates
      @bank.rates.should == {}
    end
  end

  describe '#get_rate' do
    context 'getting dicrect rates' do
      before do
        @bank.flush_rates
        @bank.add_rate('RUB', 'USD', 0.03)
        @bank.add_rate('RUB', 'GBP', 0.02)
      end

      it 'should get rate from @rates' do
        @bank.get_rate('RUB', 'USD').should == 0.03
      end

      it 'should calculate indirect rates' do
        @bank.get_rate('USD', 'GBP').should == 0.6666666666666667
      end
    end

    context 'getting indirect rate' do
      let(:indirect_rate) { 4 }

      before do
        @bank.flush_rates
        @bank.add_rate('RUB', 'USD', 123)
        @bank.add_rate('USD', 'RUB', indirect_rate)
      end

      it 'gets indirect rate from the last set' do
        expect(@bank.get_rate('RUB', 'USD')).to eq(1.0 / indirect_rate)
      end
    end

    context "when ttl is not set" do
      before do
        @bank.add_rate('RUB', 'USD', 123)
        @bank.ttl = nil
      end

      it "should not update rates" do
        @bank.should_not_receive(:update_rates)
        @bank.get_rate('RUB', 'USD')
      end
    end

    context "when ttl is set" do
      before { @bank.add_rate('RUB', 'USD', 123) }

      context "and raks are expired" do
        before do
          @bank.instance_variable_set('@rates_updated_at', Time.now - 3600)
          @bank.ttl = 3600
        end

        it "should update rates" do
          @bank.should_receive(:update_rates)
          @bank.get_rate('RUB', 'USD')
        end
      end

      context "and ranks are not expired" do
        before do
          @bank.instance_variable_set('@rates_updated_at', Time.now - 3000)
          @bank.ttl = 3600
        end

        it "should not update rates" do
          @bank.should_not_receive(:update_rates)
          @bank.get_rate('RUB', 'USD')
        end
      end
    end
  end
end
