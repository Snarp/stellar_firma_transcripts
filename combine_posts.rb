require 'yaml'

@fm_dir         = '_frontmatter'
@ep_dir         = '_content'
@dir = @out_dir = '_posts'

def gather_fnames(dir, glob='*.md')
  Dir.glob(File.join(dir, glob)).sort
end

def content_fnames
  gather_fnames(@ep_dir)
end
def meta_fnames
  gather_fnames(@fm_dir)
end


def gen_frontmatter_index
  @index = Hash.new
  meta_fnames.each do |fname|
    frontmatter = YAML::load(File.read(fname))
    if frontmatter['episode_number']
      @index[frontmatter['episode_number'].to_i] = fname
    end
  end
  @index = @index.to_a.sort_by { |v| v[0] }.to_h
  File.write('frontmatter_index.yml', @index.to_yaml)
  return @index
end

def try_combine_post(content_fname=content_fnames.first, out_dir: @out_dir)
  txt    = File.read(content_fname)
  hsh    = YAML::load(txt)
  ep_num = hsh['episode_number'].to_i
  return nil unless ep_num > 0

  frontmatter_fname = @index[ep_num]
  return nil unless frontmatter_fname

  frontmatter = File.read(frontmatter_fname).strip
  content     = File.read(content_fname).split("\n---\n").last.strip

  ep_text     = "#{frontmatter}\n\n#{content}"

  FileUtils.mkdir_p(out_dir)
  out_fname = File.join(out_dir, File.basename(frontmatter_fname))
  File.write(out_fname, ep_text)
end