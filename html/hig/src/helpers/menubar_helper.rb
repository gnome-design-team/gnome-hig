# COPYRIGHT: 2007 Brent Beardsley (brentbeardsley@gmail.com)
# LICENSE: MIT
module MenubarHelper

  # menubar creates a unordered list of links for your menu
  # Options:
  #   :selected = { :item => :a or :li, :link => true or false (default: true), any other html attributes for selected li tag }
  #   :ul = { any html attributes }
  #   :li = { any html attributes for all li tags }
  #   :a  = { any html attributes for all a tags }
  # Usage: = menubar 'foo', ['bar', '/'], 'other', :selected => { :id => 'current', :item => :a } 
  def menubar(*params)

    options = {}
    if params.last.is_a?(Hash)
      options = params.last
      params.slice!(-1, 1)
    end
    options[:ul] ||= {}; options[:li] ||= {}; options[:a] ||= {}; 
    options[:selected] ||= {}; options[:selected][:item] ||= :li; options[:selected][:link] = true unless options[:selected].has_key?(:link)
    options[:selected][:class] = 'current' if options[:selected].keys.length == 2 && options[:selected].has_key?(:item) && options[:selected].has_key?(:link)
    
    items_output = ""
    i = 0
    params.map{ |p| [*p] }.each do |param|
      i += 1
      first_last_class = (i == 1) ? 'first' : ''
      first_last_class << ' last' if i == params.length
      first_last_class.strip!

      link_output = (param.length == 1) ? link(param[0], options[:a]) : link(param[0], param[1], options[:a])
      link_href = link_output.match(/href\=\"(.*?)\"/)[1].to_s
      link_href << "index.html" if link_href[-1, 1] == '/'
      link_href << ".html" unless link_href[-5, 5] == '.html'
      selected = (link_href == current_page || link_href == current_page.sub(/^\//, ''))
      if selected
        if options[:selected][:item] == :a
          selected_options = options[:a].merge(options[:selected]).delete_if { |key, value| [:item, :link].include?(key) }
          link_output = (param.length == 1) ? link(param[0], selected_options) : link(param[0], param[1], selected_options)
          link_output = link_output.match(/>(.*?)</)[1].to_s.strip unless options[:selected][:link]
          li_options = {}.merge(options[:li])
          if first_last_class && first_last_class.length > 0
            li_options[:class] = "#{first_last_class} #{li_options[:class]}".strip
          end
          items_output << "  " + tag(:li, li_options) { link_output } + "\n"
        else
          selected_options = options[:li].merge(options[:selected]).delete_if { |key, value| [:item, :link].include?(key) }
          if first_last_class && first_last_class.length > 0 && selected_options[:class] != first_last_class
            selected_options[:class] = "#{first_last_class} #{selected_options[:class]}".strip
          end
          link_output = link_output.match(/\>(.*?)</)[1].to_s.strip unless options[:selected][:link]
          items_output << "  " + tag(:li, selected_options) { link_output } + "\n"
        end
      else
        li_options = {}.merge(options[:li])
        if first_last_class && first_last_class.length > 0
          li_options[:class] = "#{first_last_class} #{li_options[:class]}".strip
        end
        items_output << "  " + tag(:li, li_options) { link_output } + "\n"
      end
    end
    tag(:ul, options[:ul]) { "\n" + items_output }
  end

end
