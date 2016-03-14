require "jekyll/emoji/version"
require 'oga'
require 'yajl'
require 'HTTPClient'

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
        emojione-svg-embed
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
        @initialized = false
        configure(@initial_conf = conf)

        validate_format

        @emoji_map    = {}
        @encoding_map = {}

        @shortname_aliases = []
        @ascii_aliases     = []

        load_emoji_data
        build_emoji_regexp
        build_encoding_regexp
        @initialized = true
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
          codepoints = v['unicode']
          unicode = codepoints_to_unicode(codepoints)

          add_shortname_alias(v['shortname'], codepoints)
          v['aliases'].each {|a| add_shortname_alias(a, codepoints) }
          v['aliases_ascii'].each {|a| add_ascii_alias(a, codepoints) }

          map_emoji(unicode, codepoints)
          map_encoding(unicode, codepoints)
        end

        return nil
      end

      ##
      # Map an key to an HTML Entity string for faster encoding.
      # The keys also serve as an array of strings used in the emoji regexp.
      #
      # - `k` is the unicode string
      # - `v` is a dash(`-`)-delimited string of hex-formated codepoints
      #
      # @param [String] k
      # @param [String] v
      #
      def map_encoding(k, v)
        @encoding_map[k] = v.split('-').map{|cp| "&#x#{cp};" }.join

        build_encoding_regexp if @initialized
      end

      ##
      # Add an emoji to the map of all supported emojis.
      # - `k` is an string corresponding to the emoji.
      # - `v` is a dash(`-`)-delimited string of hex-formated codepoints.
      #
      # Returns true if the key was added, false if it already existed.
      #
      # @example
      #   conv = Converter.new()
      #   conv.map_emoji("\u{1F609}", '1F609')
      #
      #
      # **NOTE**: Keys added through `map_encoding`, `map_emoji`,
      # `add_shortname_alias`, and `add_ascii_alias` are all used in the same
      # fashion during the lookup of the emoji. So, the code below would work,
      # but the `:wink:` key would be added to the wrong lookup table, which
      # would mean this key wouldn't be converted to an emoji if ASCII keys
      # were disabled.
      #
      # This is a design choice added on purpose to allow addition of different
      # types of emoji aliases, which aren't limited to `:shortcode` or the
      # traditional smiley faces (`:)`, or `:P`), but also allowing the ability
      # to toggle them off if needed.
      #
      # @example
      #   conv = Converter.new()
      #   conv.add_ascii_alias(":wink:", '1F609')
      #
      #
      # @param [String] k
      # @param [String] v
      # @return [FalseClass|TrueClass]
      #
      def map_emoji(k, v)
        return false if @emoji_map.has_key? k
        @emoji_map[k] = v

        build_emoji_regexp if @initialized
        return true
      end

      ##
      # Add a shortname alias for an emoji
      # Used similarly to `map_emoji`, except that `k` is a string alias:
      #
      # Returns true if the key was added, false if it already existed.
      #
      # @example
      #   conv = Converter.new()
      #   conv.add_shortname_alias(":wink:", '1F609')
      #
      # @param [String] emoji_alias
      # @param [String] codepoints
      # @return [FalseClass|TrueClass]
      #
      def add_shortname_alias(emoji_alias, codepoints)
        return false unless map_emoji(emoji_alias, codepoints)
        @shortname_aliases << emoji_alias

        build_emoji_regexp if @initialized
        return true
      end

      ##
      # Add an ASCII alias for an emoji
      # Used similarly to `add_shortname_alias`.
      #
      # Returns true if the key was added, false if it already existed.
      #
      # @example
      #   conv = Converter.new()
      #   conv.add_shortname_alias(";-)", '1F609')
      #
      # @param [String] emoji_alias
      # @param [String] codepoints
      # @return [FalseClass|TrueClass]
      #
      def add_ascii_alias(emoji_alias, codepoints)
        return false unless map_emoji(emoji_alias, codepoints)
        @ascii_aliases << emoji_alias

        build_emoji_regexp if @initialized
        return true
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
      def build_emoji_regexp(oc = nil)
        return if oc['ascii'] == @conf['ascii'] && oc['shortname'] == @conf['shortname'] unless oc.nil?

        valid = @encoding_map.keys
        valid += @shortname_aliases if @conf['shortname']
        valid += @ascii_aliases if @conf['ascii']

        @emoji_regexp = Regexp.union(valid)
      end

      def build_encoding_regexp
        @encoding_regexp = Regexp.new (@encoding_map.keys.map{|k| Regexp.quote(k) }).join('|')
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
        @conf = configure(@initial_conf).merge(h){|k, o, n| n.nil? ? o : n }
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
            when 'emojione-svg-embed'
              before, after = split_to_nodes(str, m)
              img = emojione_svg_embed_node(codepoints)

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
        img_src = @conf['src'] || "https://cdn.jsdelivr.net/emojione/assets/#{ext}"
        img = Oga::XML::Element.new name: 'img'
        img.set('class', 'emojione')
        img.set('alt', codepoints_to_unicode(codepoints))
        img.set('src', "#{img_src}/#{codepoints}.#{ext}")

        return img
      end

      ##
      # Generates a populated {Oga::XML::Element} node.
      #
      # @param [String|Array] codepoints
      # @return [Oga::XML::Element(name:svg)]
      def emojione_svg_embed_node(codepoints)
        if @conf['src']
          data = File.open("#{@conf['src'].chomp('/')}/#{codepoints}.svg")
        else
          data = Enumerator.new do |yielder|
            HTTPClient.get("https://cdn.jsdelivr.net/emojione/assets/svg/#{codepoints}.svg") do |chunk|
              yielder << chunk
            end
          end
        end
        img = Oga.parse_xml(data).children[0]
        img.set('class', 'emojione')
        img.set('alt', codepoints_to_unicode(codepoints))

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

      def initial_conf
        @initial_conf
      end

      private :load_emoji_json, :load_emoji_data
      private :validate_format
      private :build_emoji_regexp, :build_encoding_regexp
      private :process_node
      private :emojione_img_node, :split_to_nodes
      private :codepoints_to_unicode
    end #Converter
  end #Emoji
end
