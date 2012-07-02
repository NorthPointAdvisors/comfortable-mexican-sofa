class CmsContentController < ApplicationController
  
  # Authentication module must have #authenticate method
  include ComfortableMexicanSofa.config.public_auth.to_s.constantize
  
  before_filter :load_cms_site,
                :load_fixtures
  before_filter :load_cms_page,
                :authenticate,
    :only => :render_html
  before_filter :load_cms_layout,
    :only => [:render_css, :render_js]
  
  def render_html(status = 200)
    if @cms_layout = @cms_page.layout
      app_layout = (@cms_layout.app_layout.blank? || request.xhr?) ? false : @cms_layout.app_layout
      render :inline => @cms_page.content, :layout => app_layout, :status => status, :content_type => 'text/html'
    else
      render :text => I18n.t('cms.content.layout_not_found'), :status => 404
    end
  end

  def render_sitemap
    render
  end

  def render_css
    render :text => @cms_layout.css, :content_type => 'text/css'
  end

  def render_js
    render :text => @cms_layout.js, :content_type => 'text/javascript'
  end

protected

  def load_fixtures
    return unless ComfortableMexicanSofa.config.enable_fixtures
    ComfortableMexicanSofa::Fixtures.import_all(@cms_site.hostname)
  end
  
  def load_cms_site
    logger.info "load_cms_site | params[:site_id] : [#{params[:site_id]}] | host : #{request.host.downcase} | path : #{request.fullpath}"
    logger.info "SITES | #{Cms::Site.all.map{|x| "#{x.id} : #{x.identifier}"}.join(' | ')}"

    host = request.host.downcase
    rx = /credx\.net$/
    if host =~ rx
      @cms_site = Cms::Site.find_by_identifier "credx"
      logger.info "load_cms_site | found by hardcoded regexp (#{rx.inspect}) : #{@cms_site.inspect}"
    else
      logger.info "load_cms_site | found by hard-coded default : #{@cms_site.inspect}"
      @cms_site = Cms::Site.find_by_identifier "main"
    end
=begin
    if params[:site_id]
      @cms_site = Cms::Site.find_by_id params[:site_id]
      logger.info "load_cms_site | found by site_id" if @cms_site
    else
      @cms_site = Cms::Site.find_site request.host.downcase, request.fullpath
      logger.info "load_cms_site | found by host and path" if @cms_site
    end

    ident = ComfortableMexicanSofa.config.default_site
    if @cms_site.nil? && ident.present?
      @cms_site = Cms::Site.find_by_identifier ident
      logger.info "load_cms_site | found by default" if @cms_site
    end

    if @cms_site.nil?
      @cms_site = Cms::Site.find_by_identifier "main"
      logger.info "load_cms_site | found by finger" if @cms_site
    end
=end

    if @cms_site
      logger.info "load_cms_site | we have a site : #{@cms_site.inspect}"
      if params[:cms_path].present?
        params[:cms_path].gsub!(/^#{@cms_site.path}/, '')
        params[:cms_path].to_s.gsub!(/^\//, '')
      end
      I18n.locale = @cms_site.locale
    else
      I18n.locale = I18n.default_locale
      raise ActionController::RoutingError.new('Site Not Found')
    end
  end
  
  def load_cms_page
    @cms_page = @cms_site.pages.published.find_by_full_path!("/#{params[:cms_path]}")
    return redirect_to(@cms_page.target_page.url) if @cms_page.target_page
    
  rescue ActiveRecord::RecordNotFound
    if @cms_page = @cms_site.pages.published.find_by_full_path('/404')
      render_html(404)
    else
      raise ActionController::RoutingError.new('Page Not Found')
    end
  end

  def load_cms_layout
    @cms_layout = @cms_site.layouts.find_by_identifier!(params[:identifier])
  rescue ActiveRecord::RecordNotFound
    render :nothing => true, :status => 404
  end

end
