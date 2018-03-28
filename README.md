# Litmus Inline: Example Partner Integration

A minimal example of integrating Litmus Inline with an ESP's application.

The example uses ruby and sinatra, purely for templating and for injecting
the right keys into those templates.

What's really of interest here is our example integration which is just HTML and
JavaScript contained in [views/fake_esp_app.erb](views/fake_esp_app.erb).

The example illustrates the most commonly anticipated usage pattern: a new step
within a single page ESP editor application. We've leaned on Bootstrap for a
simple tabbed navigation.

## Prerequisites

- ruby 2.4.3
- bundler

## Setup

```sh
bundle
```

## Deployment

This is structured for easy deployment to heroku. At the time of writing
deployed to https://litmus-inline-example.herokuapp.com

## Running locally

```sh
source .env && bundle exec thin start --port 4567
```

Then use http://0.0.0.0:4567

## ENV vars

(For local use place these in `./.env`)

Example:
```
export PUBLISHABLE_KEY=pk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;

# required for JWT based session signing
export SECRET_KEY=sk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
```
