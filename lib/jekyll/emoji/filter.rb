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
        # Liquid/Jekyll seem to re-create the class where filters are included
        @@__emoji_converter__ ||= Converter.new(@context.registers[:site].config)
        @@__emoji_converter__.reconfigure('format' => output_format, 'ascii' => ascii, 'shortname' => shortname)

        output = @@__emoji_converter__.convert(input)

        # Revert back to old configuration
        # NOTE: This impacts performance in certain cases
        @@__emoji_converter__.reconfigure(@@__emoji_converter__.initial_conf)

        return output
      end
    end #Filter
  end #Emoji
end

Liquid::Template.register_filter(Jekyll::Emoji::Filter)
