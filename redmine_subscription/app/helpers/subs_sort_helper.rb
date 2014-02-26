# Helpers to sort tables using clickable column headers.
#
# Author:  Stuart Rackham <srackham@methods.co.nz>, March 2005.
#          Jean-Philippe Lang, 2009
# License: This source code is released under the MIT license.
#
# - Consecutive clicks toggle the column's sort order.
# - Sort state is maintained by a session hash entry.
# - CSS classes identify sort column and state.
# - Typically used in conjunction with the Pagination module.
#
# Example code snippets:
#
# Controller:
#
#   helper :sort
#   include SortHelper
# 
#   def list
#     sort_init 'last_name'
#     sort_update %w(first_name last_name)
#     @items = Contact.find_all nil, sort_clause
#   end
# 
# Controller (using Pagination module):
#
#   helper :sort
#   include SortHelper
# 
#   def list
#     sort_init 'last_name'
#     sort_update %w(first_name last_name)
#     @contact_pages, @items = paginate :contacts,
#       :order_by => sort_clause,
#       :per_page => 10
#   end
# 
# View (table header in list.rhtml):
# 
#   <thead>
#     <tr>
#       <%= sort_header_tag('id', :title => 'Sort by contact ID') %>
#       <%= sort_header_tag('last_name', :caption => 'Name') %>
#       <%= sort_header_tag('phone') %>
#       <%= sort_header_tag('address', :width => 200) %>
#     </tr>
#   </thead>
#
# - Introduces instance variables: @sort_default, @sort_criteria
# - Introduces param :sort
#

module SubsSortHelper
  class SortCriteria
    
    def initialize
      @criteria = []
    end
    
    def available_criteria=(criteria)
      unless criteria.is_a?(Hash)
        criteria = criteria.inject({}) {|h,k| h[k] = k; h}
      end
      @available_criteria = criteria
    end
    
    def from_param(param)
      @criteria = param.to_s.split(',').collect {|s| s.split(':')[0..1]}
      normalize!
    end
    
    def criteria=(arg)
      @criteria = arg
      normalize!
    end
    
    def to_param
      @criteria.collect {|k,o| k + (o ? '' : ':desc')}.join(',')
    end
    
    def to_sql
      sql = @criteria.collect do |k,o|
        if s = @available_criteria[k]
          (o ? s.to_a : s.to_a.collect {|c| "#{c} DESC"}).join(', ')
        end
      end.compact.join(', ')
      sql.blank? ? nil : sql
    end
    
    def add!(key, asc)
      @criteria.delete_if {|k,o| k == key}
      @criteria = [[key, asc]] + @criteria
      normalize!
    end
    
    def add(*args)
      r = self.class.new.from_param(to_param)
      r.add!(*args)
      r
    end
    
    def first_key
      @criteria.first && @criteria.first.first
    end
    
    def first_asc?
      @criteria.first && @criteria.first.last
    end
    
    def empty?
      @criteria.empty?
    end
    
    private
    
    def normalize!
      @criteria ||= []
      @criteria = @criteria.collect {|s| s = s.to_a; [s.first, (s.last == false || s.last == 'desc') ? false : true]}
      @criteria = @criteria.select {|k,o| @available_criteria.has_key?(k)} if @available_criteria
      @criteria.slice!(3)
      self
    end
  end
  
  def sort_name
    controller_name + '_' + action_name + '_sort'
  end

  # Initializes the default sort.
  # Examples:
  #   
  #   sort_init 'name'
  #   sort_init 'id', 'desc'
  #   sort_init ['name', ['id', 'desc']]
  #   sort_init [['name', 'desc'], ['id', 'desc']]
  #
  def sort_init(*args)
    case args.size
    when 1
      @sort_default = args.first.is_a?(Array) ? args.first : [[args.first]]
    when 2
      @sort_default = [[args.first, args.last]]
    else
      raise ArgumentError
    end
  end

  # Updates the sort state. Call this in the controller prior to calling
  # sort_clause.
  # - criteria can be either an array or a hash of allowed keys
  #
  def sort_update(criteria)
    @sort_criteria = SortCriteria.new
    @sort_criteria.available_criteria = criteria
    @sort_criteria.from_param(params[:sort] || session[sort_name])
    @sort_criteria.criteria = @sort_default if @sort_criteria.empty?
    session[sort_name] = @sort_criteria.to_param
  end
  
  # Clears the sort criteria session data
  #
  def sort_clear
    session[sort_name] = nil
  end

  # Returns an SQL sort clause corresponding to the current sort state.
  # Use this to sort the controller's table items collection.
  #
  def sort_clause()
    @sort_criteria.to_sql
  end

  # Returns a link which sorts by the named column.
  #
  # - column is the name of an attribute in the sorted record collection.
  # - the optional caption explicitly specifies the displayed link text.
  # - 2 CSS classes reflect the state of the link: sort and asc or desc
  #
  def sort_link(column, caption, default_order)
    css, order = nil, default_order
    
    if column.to_s == @sort_criteria.first_key
      if @sort_criteria.first_asc?
        css = 'sort asc'
        order = 'desc'
      else
        css = 'sort desc'
        order = 'asc'
      end
    end
    caption = column.to_s.humanize unless caption
    
    sort_options = { :sort => @sort_criteria.add(column.to_s, order).to_param }
    # don't reuse params if filters are present
    url_options = params.has_key?(:set_filter) ? sort_options : params.merge(sort_options)
    
     # Add project_id to url_options
    url_options = url_options.merge(:project_id => params[:project_id]) if params.has_key?(:project_id)

    link_to_remote(caption,
                  {:update => "payments", :url => url_options, :method => :get},
                  {:href => url_for(url_options),
                   :class => css})
  end

  # Returns a table header <th> tag with a sort link for the named column
  # attribute.
  #
  # Options:
  #   :caption     The displayed link name (defaults to titleized column name).
  #   :title       The tag's 'title' attribute (defaults to 'Sort by :caption').
  #
  # Other options hash entries generate additional table header tag attributes.
  #
  # Example:
  #
  #   <%= sort_header_tag('id', :title => 'Sort by contact ID', :width => 40) %>
  #
  def sort_header_tag(column, options = {})
    caption = options.delete(:caption) || column.to_s.humanize
    default_order = options.delete(:default_order) || 'asc'
    options[:title] = l(:label_sort_by, "\"#{caption}\"") unless options[:title]

    sort_link_str = sort_link(column, caption, default_order)
    if sort_link_str['class="sort'].nil?
      content_tag('th', sort_link_str, options)
    else
      options[:class] = 'table_bg_selected'
      content_tag('th', sort_link_str, options)
    end
  end

  def subs_link_to_remote_content_update(text, url_params)
    link_to_remote(text,
      {:url => url_params, :method => :get, :update => 'payments', :complete => 'window.scrollTo(0,0)'},
      {:href => url_for(:params => url_params)}
    )
  end

  def subs_per_page_links(selected=nil)
    url_param = params.dup
    url_param.clear if url_param.has_key?(:set_filter)

    links = Setting.per_page_options_array.collect do |n|
      n == selected ? n : link_to_remote(n, {:update => "payments",
                                             :url => params.dup.merge(:per_page => n),
                                             :method => :get},
                                            {:href => url_for(url_param.merge(:per_page => n))})
    end
    links.size > 1 ? l(:label_display_per_page, links.join(', ')) : nil
  end

  def subs_pagination_links_full(paginator, count=nil, options={})
    page_param = options.delete(:page_param) || :page
    url_param = params.dup

    # don't reuse query params if filters are present
    url_param.merge!(:fields => nil, :values => nil, :operators => nil) if url_param.delete(:set_filter)

    html = ''
    if paginator.current.previous
      html << subs_link_to_remote_content_update('&#171; ' + l(:label_previous), url_param.merge(page_param => paginator.current.previous)) + ' '
    end

    html << (pagination_links_each(paginator, options) do |n|
      subs_link_to_remote_content_update(n.to_s, url_param.merge(page_param => n))
    end || '')

    if paginator.current.next
      html << ' ' + subs_link_to_remote_content_update((l(:label_next) + ' &#187;'), url_param.merge(page_param => paginator.current.next))
    end

    unless count.nil?
      html << [
        " (#{paginator.current.first_item}-#{paginator.current.last_item}/#{count})",
        subs_per_page_links(paginator.items_per_page)
      ].compact.join(' | ')
    end

    html
  end
end

