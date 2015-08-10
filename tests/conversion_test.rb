require 'minitest/autorun'
require 'jekyll'
require_relative '../lib/jekyll-emoji'

class TestConversion < MiniTest::Test
  def setup
    @converter = Jekyll::Emoji::Converter.new('emoji' => {
      'format': 'html',
      'ascii' => true,
      'shortname' => true
    })
  end

  def test_html
    assert_equal "&#x1F609;", @converter.convert("\u{1F609}")
    assert_equal "&#x1F609;", @converter.convert(":wink:")
    assert_equal "&#x1F609;", @converter.convert(";)")
  end

  def test_unicode
    @converter.reconfigure 'format' => 'unicode'
    assert_equal "\u{1F609}", @converter.convert("\u{1F609}")
    assert_equal "\u{1F609}", @converter.convert(":wink:")
    assert_equal "\u{1F609}", @converter.convert(";)")
  end

  def test_svg
    @converter.reconfigure 'format' => 'emojione-svg'
    img = %q{<img class="emojione" alt="3⃣" src="https://cdn.jsdelivr.net/emojione/assets/svg/0033-20E3.svg" />}
    assert_equal img, @converter.convert("\u{0033}\u{20E3}")
    assert_equal img, @converter.convert(":three:")
    assert_equal "3", @converter.convert("3")
  end

  def test_reconfiguring_aliases
    @converter.reconfigure 'ascii' => false
    assert_equal ":)", @converter.convert(":)")

    # Return to default state
    @converter.reconfigure 'ascii' => true
  end

  def test_class_blacklists
    test1 = %q{<span class="very-serious-text no-emojis">:)</span>}
    result1 = %q{<span class="very-serious-text no-emojis">:)</span>}

    test2 = %q{<span class="very-serious-text no-emojiz">:)</span>}
    result2 = %q{<span class="very-serious-text no-emojiz">&#x1F604;</span>}

    assert_equal result1, @converter.convert(test1)
    assert_equal result2, @converter.convert(test2)
  end

  def test_attr_blacklists
    test1 = %q{<span data-no-emojis>:)</span>}
    result1 = %q{<span data-no-emojis="">:)</span>}

    test2 = %q{<span data-no-emojiz>:)</span>}
    result2 = %q{<span data-no-emojiz="">&#x1F604;</span>}

    assert_equal result1, @converter.convert(test1)
    assert_equal result2, @converter.convert(test2)
  end

  def test_attr_blacklists
    test1 = %q{<code>:)</code>}
    result1 = %q{<code>:)</code>}

    test2 = %q{<span>:)</span>}
    result2 = %q{<span>&#x1F604;</span>}

    assert_equal result1, @converter.convert(test1)
    assert_equal result2, @converter.convert(test2)
  end
end
