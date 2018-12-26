defmodule OAuth2.Response do
  @moduledoc """
  Defines the `OAuth2.Response` struct which is created from the HTTP responses
  made by the `OAuth2.Client` module.

  ## Struct fields

  * `status_code` - HTTP response status code
  * `headers` - HTTP response headers
  * `body` - Parsed HTTP response body (based on "content-type" header)
  """

  require Logger
  import OAuth2.Util
  alias OAuth2.Client

  @type status_code :: integer
  @type headers     :: list
  @type body        :: binary | map

  @type t :: %__MODULE__{
    status_code: status_code,
    headers: headers,
    body: body
  }

  defstruct status_code: nil, headers: [], body: nil

  @doc false
  def new(client, code, headers, body) do
    headers = process_headers(headers)
    content_type = content_type(headers)
    serializer = Client.get_serializer(client, content_type)
    body = decode_response_body(body, content_type, serializer)
    resp = %__MODULE__{status_code: code, headers: headers, body: body}

    if Application.get_env(:oauth2, :debug) do
      Logger.debug("OAuth2 Provider Response #{inspect resp}")
    end

    resp
  end

  defp process_headers(headers) do
    Enum.map(headers, fn {k, v} -> {String.downcase(k), v} end)
  end

  defp decode_response_body("", _type, _), do: ""
  defp decode_response_body(" ", _type, _), do: ""
  # Facebook sends text/plain tokens!?
  defp decode_response_body(body, "text/plain", nil) do
    case URI.decode_query(body) do
      %{"access_token" => _} = token -> token
      _ -> body
    end
  end
  defp decode_response_body(body, "application/x-www-form-urlencoded", nil) do
    URI.decode_query(body)
  end
  defp decode_response_body(body, mime, nil) do
    if Application.get_env(:oauth2, :warn_missing_serializer, true) do
      require Logger

      Logger.warn """

      A serializer was not configured for content-type '#{mime}'.

      To remove this warning for this content-type, consider registering a serializer:

          OAuth2.Client.put_serializer(client, "#{mime}", MySerializer)

      To remove this warning entirely, add the following to your `config.exs` file:

          config :oauth2,
            warn_missing_serializer: false
      """
    end

    body
  end
  defp decode_response_body(body, _type, serializer) do
    serializer.decode!(body)
  end
end
