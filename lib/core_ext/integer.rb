# Extensions of Integer class
class Integer
  def to_bool_a(size)
    to_s(2).rjust(size, "0").chars.map { |x| x == "1" }
  end
end
