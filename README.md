# Gagan Khandate's website

A Jekyll academic homepage for GitHub Pages. The responsive layout is inspired by
[Haozhi Qi's website](https://github.com/HaozhiQi/haozhiqi.github.io), with roots in
[Jon Barron's website](https://jonbarron.info/) and Jekyll Now.

## Local preview

Run `./serve.sh`, then open http://localhost:4000. Docker builds an image with the
GitHub Pages gems on the first run.

To build without starting the server:

```sh
docker build -t gagkhan-site .
docker run --rm -v "$PWD:/site" gagkhan-site bundle exec jekyll build
```

## Editing content

- `index.html`: biography, profile links, and news. Older news uses a native
  disclosure control that works without JavaScript.
- `_posts/`: publication metadata and abstracts. Use `research-preprint` or
  `research` as the category to show a post in the corresponding homepage section.
- `images/`: portrait and publication media.
- `_includes/publication.html`: shared publication layout and expandable abstract.
- `_includes/publication-links.html`: resource buttons, shown only when a URL exists.
- `style.scss`: desktop and mobile styling.
- `_config.yml`: site identity and Jekyll settings.

The homepage has its own `index.html`; individual posts are generated at
`/publications/:title/` so posts do not overwrite the homepage during builds.
The original biography, news, publication metadata, and media are retained.
Please respect the copyright of the images and research content.
