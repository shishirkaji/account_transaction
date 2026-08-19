module CentsFormatter
  private

  def format_cents(cents)
    cents.nil? ? nil : format("%d.%02d", cents / 100, cents % 100)
  end
end
