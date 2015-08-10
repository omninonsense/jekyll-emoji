require "jekyll/emoji/version"
require 'oga'
require 'yajl'

module Jekyll
  module Emoji
    class Converter < Converter
      safe true
      priority :lowest

      Defaults = {
        'format' => 'html',
        'ascii' => false,
        'shortname' => true
      }.freeze

      Attribute_blacklist = %w{
        data-no-emoji
        data-no-emojis
      }

      Class_blacklist = %w{
        no-emoji
        no-emojis

        no_emoji
        no_emojis
      }

      Element_blacklist = %w{
        code
        pre
      }

      def initialize(conf = nil)
        parser = Yajl::Parser.new

        @@site_conf = conf
        configure(@@site_conf)

        formats = %w{
          html
          unicode
          emojione-png
          emojione-svg
        }

        if !formats.include? @conf['format']
          raise(ArgumentError, "Unknown emoji format: '#{@conf['format']}'; Supported formats are: #{formats}")
        end

        @emoji_map    = {}
        @encoding_map = {}

        @shortname_aliases = []
        @ascii_aliases     = []

        # This JSON file is nicked from the Emoji One project
        # Go shower them in love (not that kinda love :smirk:).
        emojione_json = nil
        File.open(File.expand_path('../../../emoji.json', __FILE__), 'r') do |f|
          emojione_json ||= parser.parse(f)
        end

        emojione_json.each_value do |v|
          codepoints = v['unicode'].split('-')
          unicode = codepoints.map(&:hex).pack("U*")

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

        build_emoji_regexp

        # @emoji_regexp = Regexp.new (@emoji_map.keys.map{|k| Regexp.quote(k) }).join('|')
        @encoding_regexp = Regexp.new (@encoding_map.keys.map{|k| Regexp.quote(k) }).join('|')
      end

      def build_emoji_regexp(previous_conf = nil)
        return if previous_conf == @conf

        valid = @encoding_map.keys
        valid += @shortname_aliases if @conf['shortname']
        valid += @ascii_aliases if @conf['ascii']

        @emoji_regexp = Regexp.union(valid)
      end

      def configure(h)
        if h['emoji']
          @conf = Defaults.merge(h['emoji'])
        else
          @conf = Defaults
        end
      end

      def reconfigure(h)
        previous_conf = @conf
        @conf = configure(@@site_conf).merge(h){|k, o, n| n.nil? ? o : n }
        build_emoji_regexp(previous_conf)
      end

      def matches(ext)
        ext =~ /^\.(md|markdown)$/i
      end

      def output_ext(ext)
        ".html"
      end

      ##
      # Return whether whether `node` should contain emojis or not
      #
      # @param [Oga::XML::Node] node
      #
      # @return [Boolean]
      #
      def emoji_enabled?(node)

        return true if node.is_a? Oga::XML::Document

        if node.is_a? Oga::XML::Element
          classes = node.get('class')

          return false if Element_blacklist.any? {|e| e == node.name }
          return false if Attribute_blacklist.any? {|a| node.attr(a) }
          return false unless (Class_blacklist & classes.split).empty? unless classes.nil?

        end

        return true
      end

      ##
      # Recursively add emojis to all child nodes
      #
      # @param [Oga::XML::Document|Oga::XML::Node|Oga::XML::Element] node
      #
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

        return nil
      end

      ##
      # Add emojis to {Oga::XML::Text} node
      #
      # @param [Oga::XML::Text] node
      #
      # @return [NilClass]
      #
      def process_node(node)
        str = node.text
        str.gsub!(@emoji_regexp) do |m|
          codepoints = @emoji_map[m]

          unicode_emoji = codepoints.split('-').map(&:hex).pack("U*")

          case @conf['format']
          when 'unicode', 'html'
            unicode_emoji
          when 'emojione-png', 'emojione-svg'
            vendor, ext = @conf['format'].split('-')
            loc = str.index(m)

            before = Oga::XML::Text.new
            after = Oga::XML::Text.new

            before.text = str[0...loc]
            after.text = str[loc + m.length..-1]
            img = Oga::XML::Element.new name: 'img'
            img.set('class', vendor)
            img.set('alt', unicode_emoji)
            img.set('src', "https://cdn.jsdelivr.net/#{vendor}/assets/#{ext}/#{codepoints}.#{ext}")

            if node.node_set
              node.before(before)
              node.after(after)
              node.replace img
            end

          end
        end

        return nil
      end

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
    end #Converter

    module Filter
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
