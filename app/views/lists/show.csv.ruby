require 'csv'

CSV.generate(col_sep: "\t",  encoding: 'Windows-31J') do |csv|
  @headers.each do |row|
    csv << row
  end

  @body.each do |row|
    buf = Array.new
    @headers[2].each do |head|
      buf.push(row[head])
    end
    csv << buf
  end
end
