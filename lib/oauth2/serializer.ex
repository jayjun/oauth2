defmodule OAuth2.Serializer do
  @moduledoc """
  A serializer is responsible for encoding/decoding request/response bodies.

  ## Example

      defmodule MyApp.JSON do
        def encode!(data), do: Jason.encode!(data)
        def decode!(binary), do: Jason.decode!(binary)
      end
  """

  @callback encode!(map) :: binary
  @callback decode!(binary) :: map

  @spec get(binary) :: atom
  def get(mime_type) do
    case :ets.lookup(__MODULE__, mime_type) do
      [] ->
        maybe_warn_missing_serializer(mime_type)
        OAuth2.Serializer.Null
      [{_, module}] ->
        module
    end
  end

  @spec decode!(binary, binary) :: map
  def decode!(data, type),
    do: get(type).decode!(data)

  @spec decode!(map, binary) :: binary
  def encode!(data, type),
    do: get(type).encode!(data)

  defp maybe_warn_missing_serializer(type) do
    if Application.get_env(:oauth2, :warn_missing_serializer, true) do
      require Logger

      Logger.warn """

      A serializer was not configured for content-type '#{type}'.

      To remove this warning for this content-type, consider registering a serializer:

          OAuth2.register_serializer("#{type}", MySerializer)

      To remove this warning entirely, add the following to your `config.exs` file:

          config :oauth2,
            warn_missing_serializer: false
      """
    end
  end
end
