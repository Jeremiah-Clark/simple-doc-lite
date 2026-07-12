# Introduction

Welcome to Simple Doc. This starter project builds out of the box — run
`./build.sh` from the `template/` directory and this file becomes the
first section of your PDF.

Replace the text in these files with your own content, or add more files
and list them under `input-files:` in `template/project.yaml`.

## How this project is organized

| File                        | Purpose                                 |
|-----------------------------|-----------------------------------------|
| `content/*.md`              | Your document, in plain Markdown        |
| `template/project.yaml`     | Your settings (title, fonts, layout)    |
| `template/build.sh`         | The build command — no edits needed     |

Every `#` heading starts a new page and a new numbered section. Use `##`
for subsections — they're numbered too, and both levels appear in the
table of contents.
