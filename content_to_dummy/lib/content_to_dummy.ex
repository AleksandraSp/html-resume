defmodule ContentToDummy do
  @encoded_file 'assets/resume_encoded.html'
  @encode_class_label ~s(encode)

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
      :exit, reason -> IO.puts("Do magic fails: " <> reason)
    end
  end

  @doc """
  Copies line by line src to dest file.

  ## Examples

    iex> ContentToDummy.encodeResume("test/resume_test.html")
    ~s(<html><body lang=\"en\"><div><span class=\"encode\">c5cc431075e9e932934849dfa</span><span>We can show this</span></div></body></html>)
  """
  @spec encodeResume([char]) :: [char]
  def encodeResume(filePath) do
    case File.read(filePath) do
      {:ok, body} ->
        Floki.parse(body)
        |> processNode

      {:error, reason} ->
        IO.puts("Copy of file fails: " <> reason)
    end
    |> Floki.raw_html()
    |> saveFile
  end

  @doc """
  Processes one note of the parsed HTML file . Node can be represented as tuple
  or a list if it is on deeper level.

    ## Examples
    iex> ContentToDummy.processNode([{"i", [{"class", "fa fa-birthday-cake"}], []}, {"span", [{"class", "encode"}], ["something"]}]);
    [{"i", [{"class", "fa fa-birthday-cake"}], []}, {"span", [{"class", "encode"}], ["689459d738f8c88a3a48aa9e3"]}]

    iex> ContentToDummy.processNode({"i", [{"class", "fa fa-birthday-cake"}], []});
    {"i", [{"class", "fa fa-birthday-cake"}], []}

    iex> ContentToDummy.processNode({"span", [{"class", "encode"}], ["something"]});
    {"span", [{"class", "encode"}], ["689459d738f8c88a3a48aa9e3"]}

  """
  @spec processNode({} | [] | [char]) :: [char]
  def processNode(tupleOne, doEncode \\ true) do
    cond do
      is_binary(tupleOne) ->
        if doEncode, do: doMagic(tupleOne), else: tupleOne

      is_tuple(tupleOne) ->
        {n, a, text} = tupleOne
        {n, a, processNode(text, hasEncodeClass(a))}

      is_list(tupleOne) ->
        Enum.map(tupleOne, fn a -> processNode(a, doEncode) end)

      true ->
        :unsopported_node_format
    end
  end

  @doc """
    Something

    ## Examples

    iex> ContentToDummy.hasEncodeClass([{"class", "encode"}])
    true

    iex> ContentToDummy.hasEncodeClass([{"refs", "smth"},{"class", "encode"}])
    true

    iex> ContentToDummy.hasEncodeClass([{"class", "en1code"}])
    false

    iex> ContentToDummy.hasEncodeClass([{"refs", "smth"},{"class", "en1code"}])
    false
  """
  def hasEncodeClass(arr) do
    Enum.reduce(arr, false, fn {key, val}, acc ->
      if acc === true do
        acc
      else
        key === ~s(class) and String.contains?(val, [@encode_class_label])
      end
    end)
  end

  @doc """
  Saves content to file.

  ## Examples

    iex> ContentToDummy.saveFile("aaa")
    "aaa"
  """
  @spec saveFile([char]) :: [char] | nil
  def saveFile(content) do
    case File.write(@encoded_file, content) do
      :ok ->
        content

      {:error, res} ->
        IO.inspect(res)
        nil
    end
  end
end
