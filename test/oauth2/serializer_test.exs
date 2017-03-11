defmodule OAuth2.SerializerTest do
  use ExUnit.Case, async: false
  alias OAuth2.Serializer

  doctest OAuth2.Serializer

  @json_mime "application/json"

  defmodule TestSerializer do
    def decode!(_), do: "decode_ok"
    def encode!(_), do: "encode_ok"
  end

  test "has default json serializer" do
    OAuth2.register_serializer(@json_mime, Poison)
    assert %{"foo" => 1} == Serializer.decode!(~s|{"foo": 1}|, @json_mime)
  end

  test "accepts serializer override" do
    OAuth2.register_serializer(@json_mime, TestSerializer)

    assert "decode_ok" == Serializer.decode!(~s|{"foo": 1}|, @json_mime)
    assert "encode_ok" == Serializer.encode!(%{"foo" => 1}, @json_mime)

    OAuth2.register_serializer(@json_mime, Poison)
  end

  test "fallsback to Null serializer" do
    assert OAuth2.Serializer.Null == Serializer.get("unknown")
  end
end
