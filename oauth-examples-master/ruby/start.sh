#!/bin/bash

echo "Installing bundle" &&
  bundle --quiet &&
  echo "Starting server" &&
  bundle exec ruby app.rb
