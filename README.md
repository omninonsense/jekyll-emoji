# Jekyll::Emoji

[![Build Status](https://travis-ci.org/omninonsense/jekyll-emoji.svg?branch=master)](https://travis-ci.org/omninonsense/jekyll-emoji)
[![Gem Version](https://badge.fury.io/rb/jekyll-emoji.svg)](http://badge.fury.io/rb/jekyll-emoji)
[![Code Climate](https://codeclimate.com/github/omninonsense/jekyll-emoji/badges/gpa.svg)](https://codeclimate.com/github/omninonsense/jekyll-emoji)
[![Inline docs](http://inch-ci.org/github/omninonsense/jekyll-emoji.svg?branch=master)](http://inch-ci.org/github/omninonsense/jekyll-emoji)


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

For a list of all available shortnames and asciimojis (I hope I coined this, so I can be cool) you can consult the [emoji.codes](http://emoji.codes),
[Emoji One](http://emojione.com), and
[Emoji Cheat Sheet](http://www.emoji-cheat-sheet.com/) websites.

Elements matching the following (CSS selector) will be excluded from the emojification:

~~~
[data-no-emoji], [data-no-emojis],
.no-emoji, .no-emojis, .no_emoji, .no_emojis,
code, pre
~~~

### Liquid filter

There's also a Liquid filter called `emojify`. It accepts three parameters: `format`, `ascii` and `shortname`. The former is a `String` (see above) while the latter two are `Boolean`.

```
{{ ":kissing_heart: :heart: :stuck_out_tongue:" | emojify  }}
```

## Known Issues

### `emojify` filter performance

The `emojify` filter deteriorates performance *a little* under very *specific* conditions; it shouldn't be an issue, but in case you see performance degradation when generating the site&mdash;start with this.

### `emojify` filter unawareness

The `emojify` filter isn't aware of the context it's being called within.

~~~html
<span class=".no-emoji">{{ string_with_emoji | emojify }}</span>
~~~

The content of `string_with_emoji` would be emojified, provided that there's no HTML inside `string_with_emoji` which would match the above CSS path.

### HTML Entites inside blacklisted elements

When the `emojify` filter is used inside a markdown file (say, a blog post), and if `format: 'html'` is set, then the will convert all emoji-matching unicode codepoints&mdash;regardless of whether they're inside an element matching aforementioned blacklisting CSS selector&mdash;into HTML entities (using hex format `&#xhhhh;`).

This is due to the fact that HTML encoding is done in a post-processing step to simplify and speed up the implementation.

## Development

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/omninonsense/jekyll-emoji. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

## Thanks

The following parties deserve my gratitude:
 - [Emoji One](http://emojione.com/) for creating emojis that I actually *like*, as opposed to not mind.
 - [@YorickPeterse](https://github.com/YorickPeterse) for introducing me to [Oga](https://github.com/YorickPeterse).
It was &lt;3&gt;&lt;/3&gt; at first sight!

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

### Emoji One License

If you use `emojione-png`, or ` emojione-svg`, note that the artwork is licensed under under a CC-BY-SA 4.0 International license, and you're required to include the following attribution:

~~~markdown
[Emoji One artwork][emojione] is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License][cc-by-sa].

[emojione]: http://emojione.com/
[cc-by-sa]: http://creativecommons.org/licenses/by-sa/4.0/
~~~
