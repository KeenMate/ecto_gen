defmodule EctoGen.Path do
  def prepare_directory_structure(output_location, opts) do
    MixIO.info("Preparing directory structure")

    if not opts[:auto_confirm] and not MixIO.yes?(
         "Ensuring that output location: \"#{output_location}\" is clean by deleting it. \nProceed?"
       ) do
        Mix.raise("Operation aborted")
    end

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
