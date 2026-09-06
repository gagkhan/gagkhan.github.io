# Local dev image for serving the Jekyll site with the same gems GitHub Pages uses.
# Build:  docker build -t gagkhan-site .
# Serve:  ./serve.sh   (or see that script for the raw docker command)
FROM ruby:3.3-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential git \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /site
COPY Gemfile ./
RUN bundle install
EXPOSE 4000 35729
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--livereload", "--force_polling"]
