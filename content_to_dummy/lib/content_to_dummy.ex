defmodule ContentToDummy do
  @moduledoc """
  Converts text inside html tags to unreadable text.

  """
  @doc """
  Turns content to SHA-256.

  ## Examples

    iex> ContentToDummy.doMagic("Hello world")
    "8ca00b268e5ba1a35678a1b53"

  """
  @spec doMagic(binary) :: binary
  def doMagic(content) do
    try do
      cond do
        is_binary(content) ->
          :crypto.hash(:sha256, content)
          |> Base.encode16()
          |> String.downcase()
          |> String.slice(5, 25)
        true ->
          content
      end
    catch
      :exit, reason -> IO.puts("do magic fails: " <> reason)
    end
  end

  @doc """
  Copies line by line src to dest file.

  ## Examples

    iex> ContentToDummy.copyFile("test/resume_test.html")
    ~s(<html><body lang=\"en\"><div><span class=\"encode\">c5cc431075e9e932934849dfa</span><span>We can show this</span></div></body></html>)
  """
  @spec copyFile([char]) :: [char]
  def copyFile(htmlFile) do
    case File.read(htmlFile) do
      {:ok, body} ->
        Floki.parse(body)
        |> (fn(node) ->
            cond do
              is_tuple(node) ->
                {n, a, text} = node
                {n, a, tupleDoMagic(text)}
              is_list(node) ->
                Enum.map(node, fn(listnode) ->
                  {n, a, text} = listnode
                  {n, a, doMagic(text)}
                end)
              true -> :undefined
            end
          end).()
      {:error, reason} -> IO.puts("copy file fails: " <> reason)
    end
    |> Floki.raw_html
  end

  @doc """
  Saves content to file.

  ## Examples

    iex> ContentToDummy.saveFile("aaa")
    "aaa"
  """
  @spec saveFile([char]) :: [char] | nil
  def saveFile(content) do
    case File.write("assets/resume_encoded.html", content) do
      :ok -> content
      {:error, res} ->
        IO.inspect(res)
        nil
    end
  end

  def tupleDoMagic(tupleOne, doEncode \\ true) do
    cond do
      is_binary(tupleOne) ->
        if doEncode, do: doMagic(tupleOne), else: tupleOne
      is_tuple(tupleOne) ->
        {n, a, text} = tupleOne
        {n, a, tupleDoMagic(text, hasEncodeClass(a))}
      is_list(tupleOne) ->
        Enum.map(tupleOne, fn(a) -> tupleDoMagic(a, doEncode) end)
      true ->
        "dummy"
    end
  end

  @doc """
    Something

    ## Examples

    iex> ContentToDummy.hasEncodeClass([{"class", "encode"}])
    true

    iex> ContentToDummy.hasEncodeClass([{"class", "en1code"}])
    false

    iex> ContentToDummy.hasEncodeClass([{"refs", "smth"},{"class", "en1code"}])
    false
  """
  def hasEncodeClass(arr) do
    Enum.reduce(arr, false, fn ({key, val}, acc) ->
      if acc === true do
        acc
      else
        (key === ~s(class) and String.contains?(val, [~s(encode)]))
      end
    end)
  end
end
