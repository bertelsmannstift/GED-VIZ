# GED VIZ

GED VIZ lets you create and share visualizations of global economic relations -
for research, teaching and storytelling.

The online version:

http://viz.ged-project.de

Watch the video to see how it works:

https://www.youtube.com/watch?v=FNUT-KwKd58

Questions or remarks? Send us your feedback!

http://www.ged-project.de/contact/

## Implementation

GED VIZ is a Ruby on Rails application using a MySQL database. The client side
part is written in JavaScript/[CoffeeScript](http://coffeescript.org/) using
[Backbone.js](http://backbonejs.org/), [Chaplin.js](http://chaplinjs.org) and
[Raphael.js](http://raphaeljs.com).

There is a [detailed blog post on the implementation](http://9elements.com/io/index.php/ged-viz-making-of/).

### Dependencies

- Ruby 1.9.3 (MRI) with RubyGems
- MySQL 5.1 or newer
- PhantomJS (for generating static images for slide previews, exporting and older browsers)

### Installation

- `gem install bundler`
- `bundle install`
- Adjust `config/database.yml` to your database configuration. You might use
  `config/database.yml.sample` as a template.
- `rake db:create db:migrate db:seed importer:import`
  This creates the database and imports the data. This may take several minutes.
- Start the local development server:
  `rails server`

If you deploy the software on an Internet or Intranet server, please replace the
term “GED VIZ” and trademarked logos which aren’t covered by the MIT license.
See [LICENSE.md](https://github.com/bertelsmannstift/GED-VIZ/blob/master/LICENSE.md)
for further instructions.

## About

The “Global Economic Dynamics” (GED) project of the
[Bertelsmann Foundation](http://www.bertelsmann-stiftung.de/) is intended to
contribute to a better understanding of the growing complexity of economic
developments.

Contact to the GED team: http://www.ged-project.de/contact/

Software Development: [9elements](http://9elements.com)

Technical and security contact: Mathias Schäfer,
[mathias.schaefer@9elements.com](mailto:mathias.schaefer@9elements.com),
[github.com/molily](https://github.com/molily)
