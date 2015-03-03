# RSolr::Europeana

RSolr::Europeana provides an RSolr-like library for applications to query the
Europeana API as though it was a Solr server.

## Installation

Add this line to your application's Gemfile:

    gem 'rsolr-europeana'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rsolr-europeana

## Usage

1. Get a Europeana API key at: http://labs.europeana.eu/api/registration/
2. Connect to RSolr::Europeana with your API key:
  `client = RSolr::Europeana.connect(api_key: 'YOUR_API_KEY')`
3. Send queries to the client as you would RSolr.

## License

Licensed under the EUPL V.1.1.

For full details, see [LICENSE.md](LICENSE.md).
