#!ruby

require "csv"
require "bigdecimal"
require "slop"

args = Slop.parse(suppress_errors: false) do |o|
  o.string "-f", "--file", "The CSV file name", required: true
  o.integer "-p", "--people", "The number of people", default: 3
  o.integer "-d", "--days", "The number of days", default: 1
end

# Function to convert European formatted numbers to BigDecimal
def convert_to_decimal(euro_string)
  BigDecimal(euro_string.tr(",", "."))
end

# Read the CSV file
file_path = "inputs/#{args[:file]}" # Change to your CSV file path
transactions = CSV.read(file_path, headers: true, col_sep: ",") # Adjust col_sep based on your CSV

# Categories with their respective keywords
categories = {
  "Food" => ["завтрак", "ужин", "обед", "ресторан", "кофе", "перекус", "булочная", "напитки", "магазин", "чай", "вода", "пиво", "коктейль", "коктейли", "бар"],
  "Souvenirs" => ["сувенир", "сувениры", "магнит", "подарок", "подарки", "игрушка", "игрушки", "открытк", "марка", "марки"],
  "Fuel" => ["бензин", "авто", "заправка"]
}

# Initialize a hash to store totals and transactions for each category
category_totals = Hash.new { |hash, key| hash[key] = {total: BigDecimal("0"), transactions: []} }

# Analyzing transactions for each category
transactions.each do |row|
  next unless row["categoryName"] == "Путешествия"

  categorized = false
  comment = row["comment"]
  outcome = convert_to_decimal(row["outcome"])

  categories.each do |category, keywords|
    if keywords.any? { |word| comment.downcase.include?(word.downcase) }
      category_totals[category][:total] += outcome
      category_totals[category][:transactions] << row
      categorized = true
      break
    end
  end

  unless categorized
    category_totals["Other"][:total] += outcome
    category_totals["Other"][:transactions] << row
  end
end

# Output results
category_totals.each do |category, data|
  puts "Total #{category} Expense: €#{"%.2f" % data[:total]}"
  if category == "Food"
    puts "#{category} Expense per person per day: €#{"%.2f" % (data[:total] / args[:people] / args[:days])}"
  end
  puts "#{category} Transactions:"
  data[:transactions].each { |row| puts "#{row[row.to_h.keys.first]} - #{row["outcome"]} #{row["outcomeCurrencyShortTitle"]} from #{row["outcomeAccountName"]} - #{row["comment"]}" }

  puts "\n"
  puts "---------------------------------------------------"
end
