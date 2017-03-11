defmodule OAuth2.Serializer do
  @moduledoc false

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

  @doc """
  Register a serialization module for a given mime type.

  ## Example

      iex> OAuth2.Serializer.register("application/json", Poison)
      :ok
      iex> OAuth2.Serializer.get("application/json")
      Poison
  """
  @spec register(binary, atom) :: :ok
  def register(mime_type, module) do
    :ets.insert(__MODULE__, {mime_type, module})
    :ok
  end

  @doc """
  Un-register a serialization module for a given mime type.

  ## Example

      iex> OAuth2.Serializer.unregister("application/json")
      :ok
      iex> OAuth2.Serializer.get("application/json")
      OAuth2.Serializer.Null
  """
  @spec unregister(binary) :: :ok
  def unregister(mime_type) do
    :ets.delete(__MODULE__, mime_type)
    :ok
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
