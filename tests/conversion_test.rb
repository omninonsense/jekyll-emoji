require 'minitest/autorun'
require 'jekyll'
require_relative '../lib/jekyll-emoji'

class TestConversion < MiniTest::Test
  def setup
    @converter = Jekyll::Emoji::Converter.new('emoji' => {
      'format' => 'html',
      'ascii' => true,
      'shortname' => true
    })
  end

  def test_html
    assert_equal "&#x1f609;", @converter.convert("\u{1f609}")
    assert_equal "&#x1f609;", @converter.convert(":wink:")
    assert_equal "&#x1f609;", @converter.convert(";)")
  end

  def test_unicode
    @converter.reconfigure 'format' => 'unicode'
    assert_equal "\u{1f609}", @converter.convert("\u{1f609}")
    assert_equal "\u{1f609}", @converter.convert(":wink:")
    assert_equal "\u{1f609}", @converter.convert(";)")
  end

  def test_svg
    @converter.reconfigure 'format' => 'emojione-svg'
    img = %Q{the number <img class="emojione" alt="3\u{20e3}" src="https://cdn.jsdelivr.net/emojione/assets/svg/0033-20e3.svg" /> is smaller than 4}
    assert_equal img, @converter.convert("the number \u{0033}\u{20E3} is smaller than 4")
    assert_equal img, @converter.convert("the number :three: is smaller than 4")
    assert_equal "the number 3 is smaller than 4", @converter.convert("the number 3 is smaller than 4")
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
    result2 = %q{<span class="very-serious-text no-emojiz">&#x1f604;</span>}

    assert_equal result1, @converter.convert(test1)
    assert_equal result2, @converter.convert(test2)
  end

  def test_attr_blacklists
    test1 = %q{<span data-no-emojis>:)</span>}
    result1 = %q{<span data-no-emojis="">:)</span>}

    test2 = %q{<span data-no-emojiz>:)</span>}
    result2 = %q{<span data-no-emojiz="">&#x1f604;</span>}

    assert_equal result1, @converter.convert(test1)
    assert_equal result2, @converter.convert(test2)
  end

  def test_node_blacklists
    test1 = %q{<code>:)</code>}
    result1 = %q{<code>:)</code>}

    test2 = %q{<span>:)</span>}
    result2 = %q{<span>&#x1f604;</span>}

    assert_equal result1, @converter.convert(test1)
    assert_equal result2, @converter.convert(test2)
  end
end
