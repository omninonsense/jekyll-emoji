# Jekyll::Emoji

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jekyll-emoji'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jekyll-emoji

## Usage

Add the following configuration to your `_config.yml`:

~~~yaml

gems: ['jekyll-emoji']
emoji:
  format: emojione-svg # default html
  ascii: true # default false
  shortname: true # default true
~~~

The following formats are supported: `html`, `unicode`, `emojione-png`, and ` emojione-svg`.

For a list of all available shortnames and asciimojis (I hope I coined this, so I can be cool) you can consult the [emoji.codes](http://emoji.codes) and [Emoji One](http://emojione.com) websites.

Elements matching the following CSS path will be excluded from the emoji conversion:

~~~css
code,
pre,
[data-no-emoji],
.no-emoji,
.no_emoji {}
~~~

### Liquid filter

There's also a Liquid filter called `emojify` (not very original). It accepts three parameters: `format`, `ascii` and `shortname`. The former is a `String` (see above) while the latter two are `Boolean`.

```
{{ ":kissing_heart: :heart: :stuck_out_tongue:" | emojify  }}
```

## Development

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Notes

The `emojify` filter deteriorates performance *a little* under very *specific* conditions; it shouldn't be an issue, but you've been warned. Sadly, I am not aware of a way to speed it up (apart from resorting to C).

The `emojify` filter isn't aware of the context it's being called within.

~~~html
<span class=".no-emoji">{{ string_with_emoji | emojify }}</span>
~~~

The content of `string_with_emoji` would be emojified, provided that there's no HTML inside `string_with_emoji` which would match the above CSS path.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/omninonsense/jekyll-emoji. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
