# require 'yaml'

# require 'syck'
# # forcing inline arrays for readability (need syck for this - if Psych allows it, it's not clearly documented anywhere)
# class Array
#   def to_yaml_style
#     :inline
#   end
# end

class Episode
  attr_accessor :filename, :meta, :md

  def initialize(filename=nil, meta={}, md='')
    @filename,@meta,@md=filename,meta,md
  end

  alias_method :text,        :md
  alias_method :body,        :md
  alias_method :frontmatter, :meta
  alias_method :hash,        :meta

  def title
    @meta['episode_title']
  end

  def number
    @meta['episode_number']
  end
  alias_method :num, :number

  def air_date
    @meta['date']
  end
  alias_method :date, :air_date

  def formats
    @meta['formats']
  end

  def tags
    @meta['tags']
  end

  def categories
    @meta['categories']
  end
  alias_method :category, :categories



  # FILE I/O

  def read(filename=@filename)
    @filename=filename
    return read_text(File.read(@filename))
  end
  alias_method :load_file, :read
  alias_method :load,      :read

  def read_text(text)
    @meta = YAML::load(text)        # load frontmatter to YAML
    text  = text.split("\n---\n")
    text.shift                      # drop raw frontmatter
    @md   = text.join("\n---\n")    # re-join remaining text
    return self
  end

  def write(filename=@filename)
    File.write(filename, to_str())
  end
  alias_method :save, :write

  def generate_filename(date=@meta['date'], number=@meta['episode_number'], 
                        dir: nil)
    return nil unless date && number
    fname = "#{date.strftime("%Y-%m-%d")}-#{"%03d"%number}.md"
    if dir
      File.join(dir, fname)
    else
      fname
    end
  end
  def generate_filename!(*args)
    if fname=generate_filename(*args)
      @filename=fname
    end
  end



  # UTILITY ACCESSORS

  def to_h
    {
      'filename' => @filename, 
      'meta'     => @meta, 
      'md'       => @md, 
    }
  end

  def to_str
    @meta.to_yaml(line_width: -1).strip + "\n---\n\n" + @md.strip
  end

  def keys
    @meta.keys
  end

  def [](key)
    raise ArgumentError.new if [:filename,:meta,:md].include?(key.to_sym)
    @meta[key.to_s] || @meta[key.to_sym]
  end

  def []=(key, val)
    raise ArgumentError.new if [:filename,:meta,:md].include?(key.to_sym)
    @meta[key.to_s] = val
  end




  # def insert_key(key, default: nil, pad_to: find_pad_length, 
  #                after_key: nil, before_key: nil, line_no: nil, 
  #                out_fname: @filename, simulate: true)
  #   key = key.to_s
  #   return false if @meta.keys.include?(key)

  #   str = "#{key}: "
  #   padding = " "*(pad_to-str.length)
  #   str = str+padding
  #   str = str+default.to_s             unless default.nil?

  #   lines = File.read(@filename).split("\n")

  #   last_line_no = find_last_line(lines)
  #   raise unless last_line_no

  #   if    !line_no && before_key
  #     line_no   = lines.index { |l| l.start_with?("#{before_key}:") }
  #   elsif !line_no && after_key
  #     line_no   = lines.index { |l| l.start_with?("#{after_key}:") }
  #     (line_no += 1)  if line_no
  #   end

  #   if !line_no || line_no>last_line_no
  #     line_no = last_line_no
  #   end

  #   puts "Inserting at line #{line_no}: #{str}"
  #   lines.insert(line_no, str)

  #   text = lines.join("\n")
  #   unless simulate
  #     File.write(out_fname, text)
  #     @meta = YAML::load(text)
  #   end
  #   return text
  # end
  # def find_last_line(lines)
  #   dashes = lines.map.with_index { |l,i| [i, l=='---'] }.select { |a| a[1] }
  #   return nil if dashes.count < 2
  #   return dashes[1][0]
  # end
  # def find_pad_length
  #   longest_key_length = @meta.keys.map { |k| k.to_s.length }.sort.last
  #   return longest_key_length + 2
  # end


  class << self
    def from(str)
      if str.length<=256 && str.downcase.end_with?('.md')
        return from_file(str)
      elsif str.include?("\n---\n")
        return from_text(str)
      end
    end

    def from_text(text, filename=nil)
      obj = self.new(filename)
      obj.read_text(text)
      return obj
    end

    def from_file(filename)
      obj = self.new(filename)
      obj.read
      return obj
    end
  end # class << self

end