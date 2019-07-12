# ==[ Enhancements to ActiveRecord ]==

# #!# NOTE: We should make this a class instance var instead of $global
$default_primary_key_type = :integer # bigint integer

class ActiveRecord::ConnectionAdapters::TableDefinition
  alias_method :column_real, :column
  def column(name, type, options = {})
    name = name.to_s
    type = type.to_sym if type
    options = options.dup

    # use default primary_key type
    if type == :primary_key
      options[:limit] ||= $default_primary_key_type == :integer ? 4 : 8
    end

    # alias "field!" as {null:false}
    if name =~ /!$/ and name = $`
      options[:null] = false
    end

    column_real(name, type, options)
  end

  # alias "index :name, 10" as "index :name, length: 10"
  def index(column_name, options = {})
    options = { length: options } if Numeric === options
    indexes << [column_name, options]
  end

  # alias "index!" as {unique:true}
  def index!(column_name, options = {})
    options = { length: options } if Numeric === options
    indexes << [column_name, options.merge(unique:true)]
  end
end

# use default primary_key type
class ActiveRecord::ConnectionAdapters::ReferenceDefinition
  alias_method :initialize_real, :initialize
  def initialize(name, **options)
    options[:type] ||= $default_primary_key_type
    initialize_real(name, **options)
  end
end

# aliases Numeric as limit and Array as default
module ActiveRecord::ConnectionAdapters::ColumnMethods
  [ :bigint, :binary, :boolean, :date, :datetime, :decimal, :float,
    :integer, :json, :string, :text, :time, :timestamp, :virtual
  ].each do |column_type|
    module_eval <<-CODE, __FILE__, __LINE__ + 1
      def #{column_type}(*args, **options)
        args.delete_if do |item|
          case item
          when Numeric then options[:limit  ] = item   ; true
          when Array
            case item.size
              when 1 then options[:default  ] = item[0]; true
              when 2 then options[:precision] = item[0]; options[:scale] = item[1]; true
            end
          end
        end
        options[:default] ||= false if (:#{column_type} == :boolean) && (args[0] =~ /!$/)
        args.each { |name| column(name, :#{column_type}, options) }
      end
    CODE
      # def #{column_type}!(*args, **options)
      #   #{column_type}(*args, **options.merge(index:true))
      # end
  end
  alias_method :numeric, :decimal
  alias_method :id, $default_primary_key_type # use default primary_key type
end

# use default primary_key type
class ActiveRecord::ConnectionAdapters::SchemaDumper
  def default_primary_key?(column)
    schema_type(column) == $default_primary_key_type
  end
end

# for schema dump, adjust output
class ActiveRecord::SchemaDumper
  @@wide = 14

  alias_method :header_real, :header
  def header(stream)
    buffer = StringIO.new
    header_real(buffer)
    string = buffer.string

    string = $' if string =~ /^(?=\w)/ # remove canned instructions

    stream.print string
  end

  alias_method :table_real, :table
  def table(table, stream)
    buffer = StringIO.new
    table_real(table, buffer)
    string = buffer.string

    string.sub!(/(?:, options: "[^"]*")?, force: :cascade/, '') # suppress db options
    string.gsub!(/^(.+?)("(?=, ))(.*), null: false/, '\1!\2\3') # use "!" for not null
    string.sub!(/^(?= *t.index)/, "\n") # put newline before indexes
    string.gsub!(/^( *t.index .*?), name: "index_[^"]+"/, '\1') # suppress index name
    string.gsub!(/^( *t.index)( .*?), unique: true/, '\1!\2') # unique index
    string.gsub!(/^( *t\.)(text)( .*?)(, limit: )(\d+)/) do # adjust text types
      case $5
        when "255"        then [$1, 'tinytext'  , $3].join
        when "65535"      then [$1, 'text'      , $3].join
        when "16777215"   then [$1, 'mediumtext', $3].join
        when "4294967295" then [$1, 'longtext'  , $3].join
        else $~.join
      end
    end
    string.gsub!(/^( *t\..+?), limit: (\S+)/, '\1, \2') # alias for limit
    string.gsub!(/^( *t\..+?), default: (.*?)(?= *$|, )/, '\1, [\2]') # alias for default
    string.gsub!(/^( *t.boolean +"\w+!"), \[false\]/, '\1') # default boolean is false
    string.gsub!(/, precision: (\d+), scale: (\d+)/, ', [\1, \2]') # alias for decimal(p,s)

    # line up column definitions
    @@wide = [string.scan(/^ *t\.\S+/).max_by(&:size)&.size || 0, @@wide].max
    string.gsub!(/^( *(?:t\.\S+|create_table))/) {$1.ljust(@@wide)}

    # symbolize tables, fields, and indexes
    string.gsub!(/^( *(?:t\.\S+|create_table) +)"([^"]+)"/, '\1:\2')
    string.gsub!(/^( *t\.index!? +?) \[([^\]]+)\]/) do
      list = $2.delete('"').split(', ').map(&:to_sym)
      [$1, (solo = list.size == 1) ? ' ' : '', (solo ? list[0] : list).inspect].join
    end

    stream.print string
  end

  # symbolize foreign keys
  alias_method :foreign_keys_real, :foreign_keys
  def foreign_keys(table, stream)
    buffer = StringIO.new
    foreign_keys_real(table, buffer)
    string = buffer.string

    string.gsub!(/^( *add_foreign_key .*?), name: "[^"]+"/, '\1') # suppress key name
    string.gsub!(/"([^"]+)"/, ':\1') # symbolize foreign keys

    stream.print string
  end
end

# for structure dump, suppress message about passing password to mysqldump
class ActiveRecord::Tasks::MySQLDatabaseTasks
  alias_method :prepare_command_options_real, :prepare_command_options
  def prepare_command_options
    prepare_command_options_real.delete_if {|item| item =~ /\A--.*=\z/}
  end
end

# ==[ Foreign keys and constraints ]==

# # use default primary_key type
# class ActiveRecord::ConnectionAdapters::ReferenceDefinition
#   def foreign_key_options # fix a bug?
#     opts = as_options(foreign_key)
#     opts.key?(:column) ? opts : opts.merge(column: column_name) # use a custom field
#   end
# end
#
# # allow aliases for limit and default
# module ActiveRecord::ConnectionAdapters::ColumnMethods
#   def key(*args, **options)
#     args[0] = args[0].is_a?(Symbol) ? $`.to_sym : $` if args[0] =~ /!$/
#     options[:null] = false if $` # alias "field!" as {null:false}
#
#     # fk = options[:foreign_key] || options[:foreign_key!]
#     # options[:foreign_key] = options[:foreign_key!]
#
#     options[:foreign_key] = true if (fk = options[:foreign_key]).nil?
#     options[:foreign_key] = { column: fk.to_s.chomp('!') } and id fk if fk.is_a?(Symbol)
#     references(*args, **options)
#   end
#
#   def key!(*args, **options)
#     options[:index] = {} unless Hash === options[:index]
#     options[:index].update(unique:true) # use key! for unique index
#     key(*args, **options)
#   end
# end
