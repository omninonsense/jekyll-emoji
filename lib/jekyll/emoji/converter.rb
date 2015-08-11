require "jekyll/emoji/version"
require 'oga'
require 'yajl'

module Jekyll
  module Emoji
    class Converter < Converter
      safe true
      priority :lowest

      DEFAULTS = {
        'format' => 'html',
        'ascii' => false,
        'shortname' => true
      }.freeze

      BLACKLIST_ATTRIBUTES = %w{
        data-no-emoji
        data-no-emojis
      }

      BLACKLIST_CLASSES = %w{
        no-emoji
        no-emojis

        no_emoji
        no_emojis
      }

      BLACKLIST_ELEMENTS = %w{
        code
        pre
      }

      SUPPORTED_FORMATS = %w{
        html
        unicode
        emojione-png
        emojione-svg
      }

      EMOJI_JSON_FILE = '../../../../emoji.json'

      ##
      # Initialize the object.
      # conf Hash should be the following format:
      #
      #   {
      #     ...
      #     'emoji' => {
      #       'format' => [String],
      #       'ascii' => [TrueClass|FalseClass],
      #       'shortcode' => [TrueClass|FalseClass]
      #     }
      #     ...
      #   }
      #
      # @param [Hash] conf
      #
      def initialize(conf = {'emoji' => DEFAULTS})
        @@site_conf = conf
        configure(@@site_conf)

        validate_format

        @emoji_map    = {}
        @encoding_map = {}

        @shortname_aliases = []
        @ascii_aliases     = []

        load_emoji_data
        build_emoji_regexp

        @encoding_regexp = Regexp.new (@encoding_map.keys.map{|k| Regexp.quote(k) }).join('|')
      end

      ##
      # Load up a JSON file containing emoji data, but discards the keys
      # because the json file we're reading from contains names in keys
      # which are surplus in our case.
      #
      # @param [String] path
      # @return [Array]
      #
      def load_emoji_json(path)
        parser = Yajl::Parser.new
        emoji_hash = nil
        File.open(File.expand_path(path, __FILE__), 'r') do |f|
          emoji_hash = parser.parse(f)
        end

        # keys are emoji names, we don't need those.
        return emoji_hash.values
      end

      ##
      # Populates aliases, and reference maps for faster lookup during
      # the encoding and decoding process. It acceps a path to a file
      # from which the data should be loaded.
      #
      # @param [String] path
      # @return [NilClass]
      #
      def load_emoji_data(path = EMOJI_JSON_FILE)
        data = load_emoji_json(path)

        data.each do |v|
          codepoints = v['unicode'].split('-')
          unicode = codepoints_to_unicode(codepoints)

          @shortname_aliases << v['shortname']
          @emoji_map[v['shortname']] = v['unicode']

          v['aliases'].each do |emoji_alias|
            @shortname_aliases << emoji_alias
            @emoji_map[emoji_alias] = v['unicode']
          end

          v['aliases_ascii'].each do |emoji_alias|
            @ascii_aliases << emoji_alias
            @emoji_map[emoji_alias] = v['unicode']
          end

          @encoding_map[unicode] = codepoints.map{|cp| "&#x#{cp};" }.join
          @emoji_map[unicode] = v['unicode']
        end

        return nil
      end

      ##
      # Validates if desired format is supported. If it isn't supported
      # an exception is raised.
      #
      # @param [String] f
      # @return [TrueClass]
      #
      def validate_format(f = @conf['format'])
        if !SUPPORTED_FORMATS.include? f
          raise(ArgumentError, "Unknown emoji format: '#{f}'; Supported formats are: #{SUPPORTED_FORMATS}")
        end

        true
      end

      ##
      # Rebuilds the cached Regexp object in case the converter was
      # reconfigured.
      #
      # @param [Hash|NilClass]
      # @return [Regexp]
      #
      def build_emoji_regexp(previous_conf = nil)
        return if previous_conf == @conf

        valid = @encoding_map.keys
        valid += @shortname_aliases if @conf['shortname']
        valid += @ascii_aliases if @conf['ascii']

        @emoji_regexp = Regexp.union(valid)
      end

      ##
      # Configure the internal state.
      #
      # @param [Hash] h
      # @return [Hash]
      #
      def configure(h)
        if h['emoji']
          @conf = DEFAULTS.merge(h['emoji'])
        else
          @conf = DEFAULTS
        end
      end

      ##
      # Reconfigure the internal state.
      #
      # @param [Hash] h
      # @return [Hash]
      #
      def reconfigure(h)
        previous_conf = @conf
        @conf = configure(@@site_conf).merge(h){|k, o, n| n.nil? ? o : n }
        validate_format
        build_emoji_regexp(previous_conf)

        return @conf
      end

      ##
      # Return whether we should convert a file based on its extension.
      #
      # @param [String] ext
      # @return [TrueClass|FalseClass]
      #
      def matches(ext)
        ext =~ /^\.(md|markdown)$/i
      end
      ##
      # Returns the extension with the Converter should output.
      #
      # @param [String] ext
      # @return [String]
      #
      def output_ext(ext)
        ".html"
      end

      ##
      # Return whether whether `node` should contain emojis or not.
      #
      # @param [Oga::XML::Node] node
      # @return [TrueClass|FalseClass]
      #
      def emoji_enabled?(node)

        return true if node.is_a? Oga::XML::Document

        if node.is_a? Oga::XML::Element
          classes = node.get('class')

          return false if BLACKLIST_ELEMENTS.any? {|e| e == node.name }
          return false if BLACKLIST_ATTRIBUTES.any? {|a| node.attr(a) }
          return false unless (BLACKLIST_CLASSES & classes.split).empty? unless classes.nil?

        end

        return true
      end

      ##
      # Recursively add emojis to all child nodes.
      #
      # @param [Oga::XML::Document|Oga::XML::Node|Oga::XML::Element] node
      # @return [NilClass]
      #
      def add_emojis(node)
        return unless emoji_enabled?(node)

        node.children.each do |child|
          if child.is_a?(Oga::XML::Text)
            process_node(child)
          else
            add_emojis(child)
          end
        end

        # return nil
      end

      ##
      # Add emojis to {Oga::XML::Text} node.
      #
      # @param [Oga::XML::Text] node
      # @return [NilClass]
      #
      def process_node(node)
        str = node.text

        str.gsub!(@emoji_regexp) do |m|
          codepoints = @emoji_map[m]

          case @conf['format']
          when 'unicode', 'html'
            codepoints_to_unicode(codepoints)
          when 'emojione-png', 'emojione-svg'
            before, after = split_to_nodes(str, m)
            img = emojione_img_node(codepoints)

            if node.node_set
              node.before(before)
              node.after(after)
              node.replace img
            end

            return nil
          end
        end

        return nil
      end

      ##
      # Generates a populated {Oga::XML::Element} node.
      #
      # @param [String|Array] codepoints
      # @return [Oga::XML::Element(name:img)]
      #
      def emojione_img_node(codepoints)
        ext = @conf['format'].split('-').last
        img = Oga::XML::Element.new name: 'img'
        img.set('class', 'emojione')
        img.set('alt', codepoints_to_unicode(codepoints))
        img.set('src', "https://cdn.jsdelivr.net/emojione/assets/#{ext}/#{codepoints}.#{ext}")

        return img
      end

      ##
      # Splits `str` into an {Array} with two {Oga::XML::Text} nodes at
      # `seperator`.
      #
      # @param [String] str
      # @param [String] seperator
      # @return [Array]
      #
      def split_to_nodes(str, seperator)

        before, after = str.split(seperator)

        node_before = Oga::XML::Text.new
        node_after = Oga::XML::Text.new

        node_before.text = before
        node_after.text = after || ""

        return [node_before, node_after ]
      end

      ##
      # Convert `unicode` string into a `"HHHH-HHHH"` string, which represents
      # the codepoints of the unicode string, but only if `unicode`
      # is a valid emoji.
      #
      #
      # @param [String] unicode
      # @return [String]
      #
      def unicode_to_codepoints(unicode)
        return unicode unless @encoding_map.key? unicode
        unicode.codepoints.map {|cp| cp.to_s 16}.join('-')
      end

      ##
      # Convert `codepoints` into an unicode string.
      #
      # @param [String|Array] codepoints
      # @return [String]
      #
      def codepoints_to_unicode(codepoints)
        if codepoints.is_a? String
          codepoints.split('-').map(&:hex).pack("U*")
        elsif codepoints.is_a? Array
          codepoints.map {|cp| cp.is_a?(String) ? cp.hex : cp }.pack("U*")
        else
          raise(ArgumentError, "must be String or Array")
        end
      end

      ##
      # Emojify the string. If the string is an HTML strings, certain elements
      # won't be emojified. Check the `BLACKLIST_*`` constants, or the docs for
      # more information.
      #
      # @param [String] content
      # @return [String]
      #
      def convert(content)
        document = Oga.parse_html(content)
        add_emojis(document)
        docstr = document.to_xml

        # Now we only need to encode the Emojis into HTML Entities
        if @conf['format'] == 'html'
          docstr.gsub!(@encoding_regexp, @encoding_map)
        end

        return docstr
      end # convert

      def self.site_conf
        @@site_conf
      end

      private :load_emoji_json, :load_emoji_data
      private :validate_format
      private :build_emoji_regexp
      private :process_node
      private :emojione_img_node, :split_to_nodes
      private :unicode_to_codepoints, :codepoints_to_unicode
    end #Converter
  end #Emoji
end
