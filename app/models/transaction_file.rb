class TransactionFile < ApplicationRecord
  has_many :transactions, dependent: :restrict_with_error

  def self.create_with_transactions(csv_string, name:)
    file = create!(name: name, uploaded_at: Time.current)

    rows = parse_rows(csv_string)
    file.transactions.create!(rows)
    file.update!(is_valid: true)
    file
  rescue TransactionParseError
    raise
  end

  def self.parse_rows(csv_string)
    csv_string.each_line.filter_map do |line|
      next if line.strip.empty?

      columns = line.strip.split(",", -1)
      raise TransactionParseError, "expected 3 columns, got #{columns.length}" unless columns.length == 3

      from, to, amount = columns
      amount_cents = parse_amount_to_cents(amount)
      raise TransactionParseError, "invalid amount: #{amount}" unless amount_cents&.positive?

      { from_account_number: from, to_account_number: to, amount_cents: amount_cents }
    end
  end
  private_class_method :parse_rows

  def self.parse_amount_to_cents(amount_string)
    return nil unless amount_string.match?(/\A\d+(\.\d{1,2})?\z/)

    dollars, cents = amount_string.split(".")
    dollars.to_i * 100 + (cents || "0").ljust(2, "0").to_i
  end
  private_class_method :parse_amount_to_cents

  def as_json(*)
    {
      id: id,
      name: name,
      uploaded_at: uploaded_at,
      is_valid: is_valid
    }
  end
end
