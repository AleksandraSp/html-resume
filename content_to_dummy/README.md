# ContentToDummy

**This is a customized html-resume with a small tool written in elixir that would replace all personal info with dummy content**

## Usage

Customized version of `style.css` and `resume.html` from source project resign inside `content_to_dummy/assets`.

HTML file with original resume must be added `encode` class to each leaf node which contains personal info, that we want to be encoded.
(check `assets/resume_encoded.html` for examples)

We need to compile and run the Elixir module:
```
& mix test
& mix deps.get
& mix test
& iex -S mix
iex> ContentToDummy.copyFile("assets/resume.html") |> ContentToDummy.saveFile
```
By this time a new resulting file `resume_encoded.html` is added to `assets` dir, which we can now send it around as a mock.
