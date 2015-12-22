# GED VIZ – Visualizing Global Economic Relations

GED VIZ lets you create and share visualizations of global economic relations -
for research, teaching and storytelling.

[The online version: viz.ged-project.de](http://viz.ged-project.de)

[Watch the video to see how it works](https://www.youtube.com/watch?v=FNUT-KwKd58).

Questions or remarks? [Send us your feedback!](https://www.bertelsmann-stiftung.de/de/ueber-uns/wer-wir-sind/ansprechpartner/mitarbeiter/cid/jan-arpe/)

## Implementation

GED VIZ is a data visualization tool that uses open web technologies like
HTML5, CSS, SVG, JavaScript and JSON. In particular, GED VIZ is a Ruby on
Rails application using a MySQL database. The client side part is written
 in JavaScript/[CoffeeScript](http://coffeescript.org/) using
 [Backbone.js](http://backbonejs.org/), [Chaplin.js](http://chaplinjs.org)
 and [Raphael.js](http://raphaeljs.com).

There is a
[detailed blog post on the implementation](http://9elements.com/io/index.php/ged-viz-making-of/).

### Dependencies

- Ruby 1.9.3 (MRI) with RubyGems. Also works with Ruby 2.1.
- MySQL 5.1 or newer
- [PhantomJS](http://phantomjs.org) for generating static images for slide
  previews, exporting and older browsers

### Installation

After cloning the repository, open a shell console, change to the GED-VIZ
directory and enter these commands:

- `gem install bundler`
- `bundle install`
- Adjust `config/database.yml` to your database configuration. You might use
  `config/database.yml.sample` as a template.
- `rake db:create db:migrate db:seed`<br>
  This creates the database and imports the data. This may take several minutes.
- Start the local development server:<br>
  `rails server`

This software is open source, but the trademark “GED VIZ” and the logos
are *not* covered by the MIT license. If you deploy the software on an Internet
or Intranet server, please replace these terms and logos with your own.
See [LICENSE.md](https://github.com/bertelsmannstift/GED-VIZ/blob/master/LICENSE.md)
for further instructions.

## About

The “Global Economic Dynamics” (GED) project of the
[Bertelsmann Foundation](http://www.bertelsmann-stiftung.de/) aims to
contribute to a better understanding of the growing complexity of economic developments.

Project manager: [Dr. Jan Arpe](https://www.bertelsmann-stiftung.de/de/ueber-uns/wer-wir-sind/ansprechpartner/mitarbeiter/cid/jan-arpe/)

Software Development: [9elements](http://9elements.com)

Technical and security contact: Mathias Schäfer,
[mathias.schaefer@9elements.com](mailto:mathias.schaefer@9elements.com),
[github.com/molily](https://github.com/molily)
