require "net/https"

uri = URI.parse("https://api.github.com/users/Microsoft")
puts Net::HTTP.get(uri) # => String