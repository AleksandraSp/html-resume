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

    iex> ContentToDummy.copyFile("test/resume_test.html")
    ~s(<html><body lang=\"en\"><div><span class=\"encode\">c5cc431075e9e932934849dfa</span><span>We can show this</span></div></body></html>)
  """
  @spec copyFile([char]) :: [char]
  def copyFile(filePath) do
    case File.read(filePath) do
      {:ok, body} ->
        Floki.parse(body)
        |> tupleDoMagic

      {:error, reason} ->
        IO.puts("Copy of file fails: " <> reason)
    end
    |> Floki.raw_html()
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
  @spec processNode({} | []) :: [char]
  def processNode(node) do
    cond do
      is_tuple(node) ->
        {n, a, text} = node
        {n, a, tupleDoMagic(text)}

      is_list(node) ->
        Enum.map(node, fn listnode ->
          {n, a, text} = listnode
          {n, a, tupleDoMagic(text)}
        end)

      true ->
        :undefined
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
        Enum.map(tupleOne, fn a -> tupleDoMagic(a, doEncode) end)

      true ->
        "dummy"
    end
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
end
