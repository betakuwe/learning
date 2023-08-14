# A very long line # A very long line # A very long line # A very long line # A very long line
defmodule EnumStreamsPractice do
  def large_lines!(path) do
    File.stream!(path)
    |> Stream.map(&String.trim_trailing(&1, "\n"))
    |> Enum.filter(&(String.length(&1) > 80))
  end

  def lines_length!(path) do
    for line <- File.stream!(path) do
      String.length(line)
    end
  end

  def longest_line_length!(path) do
    for length <- lines_length!(path), reduce: 0 do
      max_length -> max(max_length, length)
    end
  end

  def longest_line!(path) do
    for line <- File.stream!(path),
        String.length(line) == longest_line_length!(path) do
      line
    end
  end

  def words_per_line!(path) do
    for line <- File.stream!(path) do
      length(String.split(line))
    end
  end
end
