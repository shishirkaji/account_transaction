require 'rails_helper'

RSpec.describe CentsFormatter do
  test_class = Class.new do
    include CentsFormatter
    public :format_cents
  end
  let(:formatter) { test_class.new }

  describe "#format_cents" do
    valid_cases = {
      0 => "0.00",
      5 => "0.05",
      50 => "0.50",
      50000 => "500.00",
      100000 => "1000.00",
      999999 => "9999.99",
      123456789 => "1234567.89",
      9999999999999999999999 => "99999999999999999999.99"
    }

    valid_cases.each do |cents, expected|
      it "formats #{cents} cents as #{expected.inspect}" do
        expect(formatter.format_cents(cents)).to eq(expected)
      end
    end

    it "returns nil for nil" do
      expect(formatter.format_cents(nil)).to be_nil
    end
  end
end
