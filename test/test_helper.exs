get_modules = fn file ->
  ~r/```elixir(.+?)```/sm
  |> Regex.scan(file)
  |> Enum.map(fn [_, match] -> match end)
  |> Enum.filter(&String.contains?(&1, "defmodule"))
end

readme = File.read!("README.md")
modules = get_modules.(readme)

ExUnit.start()

Enum.each(modules, fn s ->
  file =
    System.tmp_dir!()
    |> Path.join("test_module_#{:rand.uniform(1_000_000_000)}")

  File.write!(file, s)

  Code.compile_file(file)
end)
