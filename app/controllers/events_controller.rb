#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class EventsController < ApplicationController
  before_filter :authenticate_user!

  respond_to :html
  respond_to :json, :only => [:index, :show]

  def index
    @events = current_user.visible_posts(:_type => "Event", :aspect => @aspect).paginate :page => params[:page], :per_page => 9, :order => 'created_at DESC'
    respond_with @events, :aspect => @aspect
  end

  def create
    aspect = params[:event][:to]

    data = clean_hash(params[:event])

    @event = current_user.post(:event, data)
    flash[:notice] = I18n.t 'events.create.success', :name  => @event.title
    redirect_to :action => :show, :id => @event.id, :aspect => aspect
  end

  def new
    @event = Event.new
  end

  def destroy
    @event = current_user.find_visible_post_by_id params[:id]
    @event.destroy
    flash[:notice] =  I18n.t 'events.destroy.success', :name  => @event.title
    respond_with :location => events_url
  end

  def show
    @event = current_user.find_visible_post_by_id( params[:id] )
    unless @event
      render :file => "#{Rails.root}/public/404.html", :layout => false, :status => 404
    else
      respond_with @event
    end
  end

  def edit
    @event = current_user.find_visible_post_by_id params[:id]
    redirect_to @event unless current_user.owns? @event
  end

  def update
    @event = current_user.find_visible_post_by_id params[:id]

    data = clean_hash(params[:album])

    if current_user.update_post( @event, data )
      flash[:notice] =  I18n.t 'events.update.success', :name  => @event.title
      respond_with @event
    else
      flash[:error] =  I18n.t 'events.update.failure', :name  => @event.title
      render :action => :edit
    end
  end

  private
  def clean_hash(params)
    return {
      :name => params[:name],
      :to   => params[:to]
    }
  end
end
