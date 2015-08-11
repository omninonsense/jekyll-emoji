module Jekyll
  module Emoji
    module Filter
      ##
      # Emojify the string. If the string is an HTML strings, certain elements
      # won't be emojified. Check the `BLACKLIST_*`` constants, and/or the docs
      # inside the README for more information.
      #
      # @param [String] input
      # @param [String] output_format
      # @param [FalseClass|TrueClass|NilClass] ascii
      # @param [FalseClass|TrueClass|NilClass] shortname
      # @return [String]
      #
      def emojify(input, output_format = nil, ascii = nil, shortname = nil)
        @@emoji_converter ||= Converter.new(Converter.site_conf)
        @@emoji_converter.reconfigure('format' => output_format, 'ascii' => ascii, 'shortname' => shortname)

        output = @@emoji_converter.convert(input)

        # NOTE: This impacts performance in certain cases
        @@emoji_converter.reconfigure(Converter.site_conf)

        return output
      end
    end #Filter
  end #Emoji
end

Liquid::Template.register_filter(Jekyll::Emoji::Filter)
