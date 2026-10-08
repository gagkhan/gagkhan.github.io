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

## Blog

The blog lives at `/blog/`, linked from the homepage. It lists posts in reverse
chronological order and stays separate from research publications.

To publish a post:

1. Create `_posts/blog/` if it does not exist.
2. Copy `_drafts/first-post.md` to `_posts/blog/YYYY-MM-DD-your-post-slug.md`, using
   the publication date and desired URL slug.
3. Replace the title, description, and body. Keep the `blog` category and
   `blog-post` layout. The post URL will be `/blog/your-post-slug/`.
4. Preview with `./serve.sh`, then commit and deploy when ready.

Files in `_drafts/` are excluded from normal builds. To preview drafts locally,
run `./serve.sh bundle exec jekyll serve --host 0.0.0.0 --drafts --force_polling`.
Future-dated posts are also excluded until their date; the site must rebuild
on or after that date for them to appear.
