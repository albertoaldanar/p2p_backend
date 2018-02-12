class API::V1::roomsController < ApplicationController
  def index
    if !params[:address].blank?
      rooms = Room.where(active: true).near(params[:address], 5, order: "distance")
    else
      rooms = Room.where(active: true)
    end
  end
end
