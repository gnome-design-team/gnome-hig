require 'fileutils'
require 'pp'
module NavigationHelper
  
  @@pages = []
  @@page_index = {}
  @@current_page = nil
  INDEX_PATTERN = /index\.haml/i
  STRING_PATTERN = /('(\w|\s)*')|("(\w|\s)*")/
  FIXNUM_PATTERN = /-?\d+/
  LINK_TEXT = "link_text"
  NAVIGATION_INDEX = "nav_index"
  DEFAULT_NAV_INDEX = 0
  INDEX_CHOP = true
  EXTENSION_CHOP = true
  DIV_WRAP = true
  # non english sites may want to override "home" as they see fit.
  HOME = "home"
  # constants used in building navigation
  BREAD_SEPARATORS = true
  CURRENT_AS_SPAN = true  # When false, the current item in a navigation is a hyperlink to current page (duh!)
  @@breadcrumb = false  #when true, only ancestors are displayed
  @@start_depth = 1
  @@descendants = 0
  @@separator = "&raquo;"

  # Builds a breadcrumb trail
  def breadcrumbs(separator="&raquo;", start=0)
    @@separator=separator
    if DIV_WRAP
      tag(:div, :class => "breadcrumbs"){ navigation(start, false, true) }
    else
      navigation(start, false, true)
    end
  end
  
  # Starting at the site root, builds a fully expanded sitemap
  def sitemap
    if DIV_WRAP
      tag(:div, :class => "sitemap"){ navigation(0, false) }
    else    
      navigation(0, false)
    end
  end
  
  # Displays the top level only (i.e. contents of root, without "Home" link)
  def topnav
    if DIV_WRAP
      tag(:div, :class => "topnav"){ navigation(1,0) }
    else
      navigation(1,0)
    end
  end
  
  # In conjunction with topnav, this expands to a context-relevant navigation below top
  def subnav
    if DIV_WRAP
      tag(:div, :class => "subnav"){ navigation(2,1) }
    else    
      navigation(2,1)
    end
  end
  
  # create a default navigation list, wrapped in a div.navigation
  def nav
    if DIV_WRAP
      tag(:div, :class => "navigation"){ navigation }
    else    
      navigation
    end
  end  
  
  # Create a navigation list, by default expanding to show the contents of any folders
  def navigation(start=1, descendants=1, breadcrumb=false)
    setup
    reset(start, descendants, breadcrumb)
    nav = unordered_list(navigation_origin)
    reset
    return nav
  end
  
  
  # ========================================================================================
  private
  # ========================================================================================
    
  # scan the /src/pages directory for all pages, 
  # building @@pages list (where order is significant)
  # and @@page_index for easy retreival of any page by its relative path
  def setup
    if @@current_page != relative_path_of_current_page
      @@current_page = relative_path_of_current_page
      @@pages = scan_directory(File.join(@staticmatic.src_dir, "pages", "*"))
      current_page = @@page_index[@@current_page]
      current_page.set_current
      mark_ancestors(current_page)
    end
  end
  
  # Ensure that default values are restored after using any helper methods by calling this
  def reset(start=1, descendants=1, breadcrumb=false)
    @@breadcrumb = breadcrumb
    @@start_depth = start
    @@descendants = descendants
  end
  
  
  # determine the starting point for constructing a navigation. 
  # If given start_depth = 0 or 1, start with root folder or its contents
  # start_depth >= 2 must find the origin w.r.t. the current page.
  def navigation_origin
    if @@start_depth == 0
      origin = [@@pages]
    elsif @@start_depth == 1
      origin = @@pages.child
    else
      origin = find_origin(@@page_index[@@current_page])
    end
  end
  
  
  def find_origin(page)
    if page.depth == @@start_depth
      return page.siblings
    elsif page.depth > @@start_depth
      return find_origin(page.parent)
    else
      page.child.each do |ch|
        return find_origin(ch)
      end
      return nil
    end
  end
  
  # create a <ul>, and populate it with <li> for each page below the current one.
  def unordered_list(pagelist)
    return "" if pagelist.nil?
    output = tag(:ul) do
      list_items = ""
      pagelist.each do |page|
        item = @@breadcrumb ? breadcrumb_list_item(page) : listitem(page)
        list_items << item if item
      end
      list_items
    end
    return output
  end
  
  # create a <li> out of a page.
  # If the page has descendants, they may be nested 
  # as a <ul> within the current <li>.
  def listitem(page)
    tag(:li, :class => list_class(page)) do
      content = anchor_or_span(page)
      content << next_level(page)
    end
  end
  
  # Breadcrumb trails differ from other navigations, in that
  # a page should only be displayed if it is an ancestor to the
  # current page. Also, a separator may be inserted between crumbs.
  def breadcrumb_list_item(page)
    if page.is_ancestor? or page.is_current?
      li_class = bread_list_class(page)
      tag(:li, :class => li_class) do 
        content = ""
        if BREAD_SEPARATORS and !li_class.include?("first")
          content << tag(:span, :class => "separator"){@@separator}
        end
        content << anchor_or_span(page)
        content << next_level(page)
      end
    end
  end

  # when displaying the current item in a navigation, 
  # it makes sense to use a <span> instead of an <a>
  # this method outputs wraps link text accordingly
  def anchor_or_span(page)
    if CURRENT_AS_SPAN and page.is_current?
      tag(:span){ page.link }
    else
      tag(:a, :href => "#{page.relative}"){page.link}
    end
  end
  
  # applies appropriate classes to a list-item, handles for styling
  def list_class(page)
    first = "first " if page.previous.nil?
    last = "last " if page.next.nil?
    ancestor = "ancestor " if page.is_ancestor?
    current = "current " if page.is_current?
    [first, last, ancestor, current].join(" ")
  end

  # determine which classes to apply to a <li class="?"> in a breadcrumb trail
  def bread_list_class(page)
    first = "first" if page.depth == @@start_depth
    last = "last" if page.is_current?
    [first, last].join(" ")
  end
  
  # Decide whether to expand the next level of navigation
  def next_level(page)    
    return "" unless page.has_children?
    if !@@descendants
      return unordered_list(page.child)
    elsif @@descendants == 0
      return ""
    elsif @@descendants == 1
      if page.is_current? or page.is_ancestor?
        return unordered_list(page.child)
      else
        return ""
      end
    end
  end
  
  def relative_path_of_current_page
    relative_path(@staticmatic.current_page)
  end
  
  # go through ancestors, marking them as such  
  def mark_ancestors(page)
    if page.has_parent?
      page.parent.set_ancestor
      mark_ancestors(page.parent)
    end
  end
  
  def scan_directory(path, parent=nil, depth=1)
    # find or create index.haml file
    dir = index_file(path, depth-1)
    dir.parent = parent
    
    Dir[path].each do |item|
      if File.directory?(item)
        index = scan_directory(File.join(item,"*"), dir, depth+1)
        dir.add_child(index)
      else
        # be sure to skip the index file!
        if item.index(INDEX_PATTERN)
          next
        end
        # next if item.index(INDEX_PATTERN)
        page = create_page(item, depth)
        dir.add_child(page)
      end
    end
    dir.child.sort
    connect_siblings(dir.child)
    return dir
  end
  
  # 
  def connect_siblings(list)
    list.size.times do |index|
      current = list[index]
      current.previous = index == 0 ? nil : list[index-1]
      current.next = index == list.size ? nil : list[index+1]      
    end
  end
  
  # Given path, look for a file called index.
  # If found: create and return a Page object from that file 
  # else:     create an index file at the given path, 
  #           constructing a Page object from it.
  def index_file(path,depth)
    index = nil
    Dir[path].each do |item|
      next if File.directory?(item)
      if item =~ INDEX_PATTERN
        return index = create_page(item, depth)
      end
    end
    index = create_index_file(path,depth)
    index
  end
  
  # create an index file, saving to disk
  def create_index_file(path,depth)
    content = "/ #{path}\n/ #{depth}\n/The navigation_helper requires that each directory contains a file called index.haml. This file was automatically generated, so be sure to replace this content with something meaningful, or you'll have egg on your face.\n-@title ='Navigation helper'\n%p Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    # the path ends with '*' so chop that off before creating a new path
    newfile = File.join(path[0...-1], "index.haml")
    File.open(newfile, "w") do |f|
      f.puts content
    end
    # now create a page object for it
    create_page(newfile,depth)
  end
  
  # Searches through a file at "path", for a variable named "target" with same class as "type"
  def find_variable_in_file(path, target, type)
    var = nil
    File.open(path) do |file|
      file.each_line do |line|
        if index = line.rindex(target)
          range = line.slice(index+target.length..-1)
          if type.class == String
            # Find the portion in quotes, then slice out the quotes
            var = range.slice(STRING_PATTERN).slice(1...-1)
          end
          if type.class == Fixnum
            var = range.slice(FIXNUM_PATTERN).to_i
          end
        end
      end
    end
    return var
  end  
  
  def create_page(path, depth)
    relative = relative_path(path)
    p "relative: #{relative}"
    link = get_link_from_file(path)
    index = get_nav_index_from_file(path)
    p "index: #{index}"
    newpage = Page.new(path, relative, link, index, depth)
    # add the page to an index, for easy retrieval
    index_pages(newpage)
    return newpage
  end
  
  def index_pages(page)
    # @@page_index[page.absolute] = page  #changed
    @@page_index[page.relative] = page
  end
  
  # Given an absolute path, returns a relative path
  # e.g.  "./src/pages/products/index.haml"  => "/products/"
  #       "./src/pages/products/frisbee.haml"  => "/products/frisbee"
  def relative_path(path, index_chop = INDEX_CHOP, extension_chop = EXTENSION_CHOP)
    needle = File.join(@staticmatic.src_dir, "pages")
    index = path.rindex(needle)
    relative = path.slice(index+needle.length..-1)
    if index_chop
      discard_slice = relative.slice!(INDEX_PATTERN)
    end
    if extension_chop
      relative.chomp!(File.extname(relative))
    end
    return relative
  end  
  
  # fetches the link text from a file at "path"
  def get_link_from_file(path)
    link = find_variable_in_file(path, LINK_TEXT, "")
    if link.nil?
      if path =~ INDEX_PATTERN
        # e.g. /index.haml should be named 'home'
        # e.g. /programs/index.haml should be named 'programs'
        # the above would split to: ["index.haml"] and ["programs", "index.haml"]
        # so take levels[-2]
        levels = relative_path(path, false).split("/")
        link = levels[-2]
        if link == ""
          return HOME
        else
          return link
        end        
      end
      link = path[path.rindex(File::SEPARATOR)+1..-1].gsub(/_/, " ")
      return link.chomp(File.extname(path))
    end
    link
  end
  
  # fetches a navigation index from file at "path"
  def get_nav_index_from_file(path)
    index = find_variable_in_file(path, NAVIGATION_INDEX, 0)
    index.nil? ? DEFAULT_NAV_INDEX : index
  end
  
  class Page

    def initialize( absolute='', relative='', link='', index=0, depth=0, parent=nil, child=[])
      @absolute = absolute
      @relative = relative
      @link = link
      @nav_index = index
      @depth = depth
      @parent = parent
      @child = child
      @previous = nil
      @next = nil
      @current = false
      @ancestor = false
    end
    attr_reader :relative, :absolute, :link, :nav_index
    attr_accessor :depth, :parent, :child, :previous, :next
    attr_writer :current, :ancestor

    def siblings
      siblings = @parent.nil? ? nil : @parent.child
    end
    
    def set_current(value=true)
      @current = value
    end
    
    def set_ancestor(value=true)
      @ancestor = value
    end
    
    def is_current?
      @current
    end
    
    def is_ancestor?
      @ancestor
    end

    def <=>(other)
      index = self.nav_index <=> other.nav_index
      index == 0 ? self.link <=> other.link : index
    end

    def has_parent?
      parent
    end

    def has_children?
      !child.nil? && !child.empty?
    end

    def make_parent(parent)
      if parent.class == Page
        parent.child << self
        self.parent = parent
      end
    end
    
    def add_child(newchild)
      self.child << newchild
      newchild.parent = self
    end
    
    def to_s
      output = "relative: #{@relative},  "
      output << "absolute: #{@absolute},  "
      output << "link: #{@link},  "
      output << "nav_index: #{@nav_index},  "
      output << "depth: #{@depth}"
    end

  end
  
end