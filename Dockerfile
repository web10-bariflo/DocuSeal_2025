# Use Ruby 3.4.2 base image
FROM ruby:3.4.2-slim AS base

# Install system dependencies for Ruby, Node.js, PostgreSQL, MySQL, Git, and libvips
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    libyaml-dev \
    libmariadb-dev \
    libvips-dev \
    nodejs \
    npm \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install Yarn via npm
RUN npm install -g yarn@1.22.22

# Stage for installing Ruby and Node.js dependencies
FROM base AS dependencies

# Copy Gemfile and Gemfile.lock for Ruby dependencies
COPY Gemfile Gemfile.lock ./

# Install Ruby gems with the correct Bundler version
RUN gem install bundler -v 2.5.3 && bundle install --jobs 4 --retry 3

# Copy package.json and yarn.lock for Node.js dependencies
COPY package.json yarn.lock ./

# Install Node.js dependencies with increased network timeout
RUN yarn install --network-timeout 100000

# Final stage for the application
FROM base

# Copy installed dependencies from the dependencies stage
COPY --from=dependencies /usr/local/bundle /usr/local/bundle
COPY --from=dependencies /app/node_modules /app/node_modules

# Copy the rest of the application code
COPY . .

# Clean asset cache and precompile assets
RUN rm -rf tmp/cache public/assets && bundle exec rake assets:precompile

# Expose port 3000 (default for Rails)
EXPOSE 3000

# Command to start the Rails server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
