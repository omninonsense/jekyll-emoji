require 'minitest/autorun'
require 'jekyll'
require_relative '../lib/jekyll-emoji'

class TestConversion < MiniTest::Test
  def setup
    @converter = Jekyll::EmojiConverter.new('emoji' => {
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
end
