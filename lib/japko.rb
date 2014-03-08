require 'japko/version'
require 'parslet'
require 'parslet/convenience'

module Japko
  class Parser < Parslet::Parser

    def quoted(atom)
      quote >> atom >> quote
    end

    def curly_braced(atom)
      str('{') >> atom >> str('}')
    end

    def maybe_spaced(atom)
      space? >> atom >> space?
    end

    rule(:quote)       { str('"') }
    rule(:equals)      { str('=') }
    rule(:semicolon)   { str(';') }
    rule(:linebreak)   { match('\\n') }
    rule(:linebreak?)  { linebreak.maybe }
    rule(:space)       { match('\s').repeat(1) }
    rule(:space?)      { space.maybe }
    rule(:string)      { quoted((quote.absent? >> any).repeat.as(:string)) }
    rule(:pair)        { maybe_spaced(string.as(:key)) >> equals >> maybe_spaced(string.as(:value)) >> semicolon }
    rule(:data)        { curly_braced(linebreak? >> (pair >> linebreak?).repeat) }
    root(:data)

  end

  class Transform < Parslet::Transform

    rule(:string => simple(:x)) { x.to_s }
    rule(:key => simple(:key), :value => simple(:value)) { { key => value } }

  end

  def self.parse(data)
    list_of_pairs = Transform.new.apply(Parser.new.parse(data))
    list_of_pairs.inject({}) { |hash, pair| hash.merge(pair) }
  end

end