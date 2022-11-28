$default_primary_key_type = :integer

# NOTE: It would be great if the following worked, but I get this error:
#       "TypeError: superclass mismatch for class SchemaDumper"
#
# class ActiveRecord::ConnectionAdapters::SchemaDumper
#   private
#     def default_primary_key?(column)
#       schema_type(column) == $default_primary_key_type
#     end
# end

class ActiveRecord::SchemaDumper

  alias_method :header_real, :header
  def header(stream)
    buffer = StringIO.new
    header_real(buffer)
    string = buffer.string

    # adjust header to keep it simple
    string = $' if string =~ /^(?=\w)/ # skip past comments
    string.sub!(/(?<=Schema)\[[^\]]*\](?=\.define)/, '') # remove version
    string << "\n"

    stream.print string
  end

  alias_method :table_real, :table
  def table(table, stream)
    buffer = StringIO.new
    table_real(table, buffer)
    string = buffer.string

    # adjust table descriptions using shorthand notation
    string.sub!(/, id: :#{$default_primary_key_type}\b/o, '') # skip primary keys with default type #!# TODO: remove when we fix the class issue above
    string.sub!(/(?:, (?:charset|collation|options): "[^"]*")*, force: :cascade/, '') # skip options
    string.gsub!(/^(.+?)("(?=, ))(.*), null: false/, '\1!\2\3') # add "!" to column name for not null
    string.gsub!(/^( *t\.)(text)( .*?)(, limit: )(\d+)/) do # adjust text types
      case $5
        when "255"        then [$1, 'tinytext'  , $3].join
        when "65535"      then [$1, 'text'      , $3].join
        when "16777215"   then [$1, 'mediumtext', $3].join
        when "4294967295" then [$1, 'longtext'  , $3].join
        else $~.join
      end
    end
    string.gsub!(/^( *t\..+?), limit: (\S+)/, '\1, \2') # "limit: x" is "x"
    string.gsub!(/^( *t\..+?), default: (.*?)(?= *$|, )/, '\1, [\2]') # "default: x" is "[x]"
    string.gsub!(/^( *t\.boolean +"\w+!"), \[false\]/, '\1') # booleans default to false, so skip
    string.gsub!(/, precision: nil/, '') # skip useless precision values
    string.gsub!(/, precision: (\d+), scale: (\d+)/, ', [\1, \2]') and # "decimal(p,s)" is "[p, s]"
    string.gsub!(/, \["(\d+)\.0"\]/, ', [\1]') # adjusts defaults like ["4.0"] to [4]
    string.gsub!(/t\.decimal ("[^"]+"), \[9, 2\], \[0\]$/, 't.digits \1') # use t.digits shortcut

    # adjust indexes
    string.sub!(/^(?= *t.index)/, "\n") # add a spacer line before indexes
    string.gsub!(/^( *t.index .*?), name: "index_[^"]+"/, '\1') # strip generated index names
    string.gsub!(/^( *t.index)( .*?), unique: true/, '\1!\2') # add "!" for unique indexes

    # line up column names
    wide =[string.scan(/^ *t\.\S+/).map(&:size).max, 14].max
    string.gsub!(/^( *(?:t\.\S+|create_table))/) {$1.ljust(wide)}

    # line up column options
    wide = string.scan(/^ *t\.(?!index)[^,\n]+/).map(&:size).max
    string.gsub!(/^( *t\.(?!index)[^,\n]+(?=,))/) { $1.ljust(wide)}

    # symbolize tables, fields, and indexes
    string.gsub!(/^( *(?:t\.\S+|create_table) +)"([^"]+)"/, '\1:\2')
    string.gsub!(/^( *t\.index!? +?) \[([^\]]+)\]/) do
      list = $2.delete('"').split(', ').map(&:to_sym)
      [$1, (solo = list.size == 1) ? ' ' : '', (solo ? list[0] : list).inspect].join
    end

    stream.print string
  end

  alias_method :foreign_keys_real, :foreign_keys
  def foreign_keys(table, stream)
    buffer = StringIO.new
    foreign_keys_real(table, buffer)
    string = buffer.string

    # adjust foreign key descriptions
    string.gsub!(/^( *add_foreign_key .*?), name: "[^"]+"/, '\1') # suppress key name
    string.gsub!(/"([^"]+)"/, ':\1') # symbolize foreign keys

    stream.print string
  end
end
