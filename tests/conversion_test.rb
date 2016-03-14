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

  def test_src
    @converter.reconfigure 'format' => 'emojione-svg', 'src' => '/assets/svg'
    img = %Q{the number <img class="emojione" alt="3\u{20e3}" src="/assets/svg/0033-20e3.svg" /> is smaller than 4}
    assert_equal img, @converter.convert("the number \u{0033}\u{20E3} is smaller than 4")
    assert_equal img, @converter.convert("the number :three: is smaller than 4")
    assert_equal "the number 3 is smaller than 4", @converter.convert("the number 3 is smaller than 4")
  end

  def test_svg_embed
    @converter.reconfigure 'format' => 'emojione-svg-embed'
    img = %Q{the number <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" enable-background="new 0 0 64 64" class="emojione" alt="3\u{20e3}"><path fill="#d0d0d0" d="m61.978 51.994c0 5.523-4.478 10-10 10h-40c-5.522 0-10-4.477-10-10v-40c0-5.523 4.478-10 10-10h40c5.522 0 10 4.477 10 10v40"></path><path fill="#fff" d="m56.978 45.66c0 4.604-3.731 8.334-8.333 8.334h-33.33c-4.602 0-8.333-3.73-8.333-8.334v-33.33c0-4.604 3.731-8.334 8.333-8.334h33.33c4.602 0 8.333 3.73 8.333 8.334v33.33"></path><path fill="#9aa0a5" d="m21.978 36.15l5.585-.707c.179 1.482.657 2.617 1.438 3.4s1.725 1.176 2.834 1.176c1.19 0 2.193-.471 3.01-1.41.814-.941 1.223-2.209 1.223-3.807 0-1.51-.391-2.707-1.172-3.59-.781-.885-1.731-1.324-2.854-1.324-.74 0-1.623.148-2.65.447l.637-4.895c1.561.043 2.752-.311 3.573-1.059s1.232-1.742 1.232-2.982c0-1.055-.301-1.896-.903-2.521-.603-.627-1.404-.941-2.403-.941-.985 0-1.827.355-2.525 1.068s-1.122 1.752-1.273 3.121l-5.317-.939c.369-1.896.928-3.41 1.674-4.543.745-1.133 1.785-2.023 3.121-2.672 1.334-.648 2.83-.973 4.486-.973 2.833 0 5.106.939 6.816 2.822 1.41 1.539 2.115 3.275 2.115 5.215 0 2.75-1.444 4.945-4.332 6.584 1.725.385 3.104 1.246 4.138 2.586 1.033 1.34 1.55 2.957 1.55 4.854 0 2.75-.965 5.094-2.895 7.03-1.932 1.938-4.334 2.908-7.208 2.908-2.724 0-4.983-.816-6.776-2.447-1.795-1.633-2.835-3.768-3.123-6.402"></path></svg> is smaller than 4}
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
