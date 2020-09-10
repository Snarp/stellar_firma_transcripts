require 'faraday'
require 'oga'
require_relative 'episode'

@url       = 'https://stellarscripts.tumblr.com/transcripts/'
@out_fname = 'source_index.yml'
@ep_dir    = '../_posts'


# EDITING EPISODES

def episode_fnames(dir=@ep_dir)
  Dir.glob(File.join(dir, '*.md')).sort
end

def add_formats_to_all_episodes
  episode_fnames.map do |fname|
    add_formats_to_episode(fname)
  end
end

def add_formats_to_episode(fname=episode_fnames[1])
  puts "Parsing file: #{fname}"
  ep = Episode::from_file(fname)
  ep_num = ep.number.to_i
  return nil unless ep_num > 0
  return nil unless ep_info=@source_index[ep_num]

  formats = ep_info[:formats]
  return nil unless formats && formats.any?

  puts "Editing file: #{fname}"

  ep.meta['formats'] = formats
  ep.meta['sources'] = {'stellarscripts'=>'http://stellarscripts.tumblr.com/'}
  ep.save

  return ep
end



# SCRAPING URLS

def scrape_source_index(doc=doc(), out_fname=@out_fname)
  @source_index = { problems: [] }
  doc.css('div.posts tr').map do |tr|
    links = tr.css('a')
    next unless links.any?

    title = links.first.text.strip

    if ep_num = /Episode (\d+)/.match(title)
      ep_num = ep_num[1].to_i
    end

    ep = {
      num:   ep_num, 
      title: title, 
      formats: {
        'HTML' => try_purge_tumblr_referral_crap(links.first.get('href')), 
        'Google Doc' => try_purge_tumblr_referral_crap(links.last.get('href')),
      }
    }.select {|k,v| v}
    slug = ep_num || title

    if @source_index[slug].nil?
      @source_index[slug] = ep
    else
      @source_index[:problems].push([slug, ep])
    end
  end

  @source_index.delete(:problems) if @source_index[:problems].empty?

  File.write(out_fname, @source_index.to_yaml)
  return @source_index
end

def try_purge_tumblr_referral_crap(link_url)
  return link_url if !link_url || !link_url.include?('t.umblr.com')
  uri  = URI(link_url)
  return link_url unless uri.query
  args = CGI::parse(uri.query)
  if args['z']
    return args['z'].first
  else
    return link_url
  end
end

def fetch_page(url=@url)
  html = Faraday.get(url).body
  return Oga::parse_html(html.force_encoding('UTF-8'))
end

def doc
  @doc ||= fetch_page
end