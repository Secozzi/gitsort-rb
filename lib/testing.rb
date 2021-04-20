width = 120
sizes = [4, 13, 25, 5, 11, 10, 8, 7, 20]

def table_length(arr)
    arr.inject(0){|sum,x| sum + x + 2} + arr.length + 1
end

temp = sizes.dup
constraints = [0] * temp.length
while table_length(temp) > width
    maxi = temp.index(temp.max)
    temp[maxi] -= 1
end

p sizes
p temp
p sizes.zip(temp).map { |a, b| a - b}

puts table_length(sizes)
puts table_length(temp)


"ABCD"

"AB…"