defmodule EctoGen.Path do
  def prepare_directory_structure(output_location) do
    File.rm_rf(output_location)

    [
      output_location,
      Path.join(output_location, "models"),
      Path.join(output_location, "parsers")
    ]
    |> ensure_locations()
  end

  defp ensure_locations(output_locations) do
    output_locations
    |> Enum.map(fn x ->
      case File.mkdir(x) do
        :ok ->
          {:ok, x}

        {:error, :eexist} ->
          {:exist, x}

        {:error, reason} ->
          Mix.raise(
            "Could not create directory at output location: #{x}. reason: #{inspect(reason)}"
          )

          {:error, x}
      end
    end)
  end
end
