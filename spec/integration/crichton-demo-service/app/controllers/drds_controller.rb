class DrdsController < ApplicationController
  respond_to(:html, :xhtml, :hale_json, :hal_json)
  
  def show
    @drd = Drd.find_by_uuid(params[:id])
    if @drd.nil?
      error = Error.new({ title: 'Item not found',
                          error_code: :item_not_found,
                          http_status: 404,
                          details: "The item with id #{params[:id]} could not be found",
                          controller: self})
      respond_with(error, status: 404)
    else
      respond_with(@drd, options)
    end
  end
  
  def index
    if (params[:search_term] == 'search')
      error = Error.new({ title: 'Not supported search term',
                          error_code: :search_term_is_not_supported,
                          http_status: 422,
                          details: 'You requested search but it is not a valid search_term',
                          controller: self})
      respond_with(error, status: 422)
    else
      @drds = Drds.find(params[:search_term])
      respond_with(@drds, options)
    end
  end
  
  def create
    @drd = Drd.new(drd_params)
    if @drd.save
      respond_with(@drd, options)
    else
      raise @drd.errors.full_messages
    end
  end
  
  def update
    @drd = Drd.find_by_uuid(params[:id])
    
    if @drd.update_attributes(drd_params)
      respond_with(@drd, options)
    else
      raise @drd.errors.full_messages
    end
  end
  
  def destroy
    @drd = Drd.find_by_uuid(params[:id])
    @drd.destroy
    respond_with(@drd, options)
  end
  
  def activate
    transition
  end

  def deactivate
    transition
  end
  
  private
  
  def transition
    @drd = Drd.find_by_uuid(params[:id])

    if @drd.send(params[:action])
      respond_with(@drd, options)
    else
      raise @drd.errors.full_messages
    end
  end

  def drd_params
    params.slice(:name, :leviathan_uuid, :kind).reject { |_, v| v.blank? }
  end
  
  def options
    (conditions = params[:conditions]) ? {conditions: conditions.split(',').map(&:strip)} : {}
  end
end
