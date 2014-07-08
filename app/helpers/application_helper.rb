module ApplicationHelper

  def controller?(*controller)
    controller.include?(params[:controller])
  end

  def action?(*action)
    action.include?(params[:action])
  end

  def active_class(keyword, clz='active')
    if keyword.include? '-'
      clz if controller?(keyword.split('-')[0]) and action?(keyword.split('-')[1])
    else
      clz if controller? keyword
    end

  end

  def title_tag
    c = (params[:controller].split('/').map {|e| e.humanize}).join ' » '
    title = @page_title ? "Qomo | #{@page_title}" : "Qomo | #{c}"
    content_tag 'title', title
  end

  def page_title(title)
    @page_title = title
  end
end
