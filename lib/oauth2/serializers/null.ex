defmodule OAuth2.Serializer.Null do
  @moduledoc false

  @behaviour OAuth2.Serializer

  @doc false
  def decode!(data), do: data

  @doc false
  def encode!(data), do: data
end
