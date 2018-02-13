class API::V1::roomsController < ApplicationController
  def index
    if !params[:address].blank?
      rooms = Room.where(active: true).near(params[:address], 5, order: "distance")
    else
      rooms = Room.where(active: true)
    end

    if !params[:start_date].blank? && !params[:end_date].blank?
      start_date = DateTime.parse(params[:start_date])
      end_date = DateTime.parse(params[:end_date])
      rooms = rooms.select { |room|
          #Checar cuantos cuartos se empalman con las fechas de mi reservacion.
          reservations = Reservation.where(
            "room_id = ? AND (start_date <= ? AND end_date >=?) AND status = ?",
            room.id, end_date, start_date, 1
          ).count
          #Checar si hay algun dia no disponible en la fecha de reservación.
          calendars = Calendar.where(
            "room_id = ? AND status = ? AND day BETWEEN ? AND ?",
            room.id, 1, start_date, end_date
          ).count

          reservations == 0 && calendars == 0
       }
    end

    render json: {
      rooms: rooms.map {|room| room.attributes.merge(image:room.cover_photo("medium"), instant: room.instant != "Request")},
      is_success: true
    },stauts: :ok

  end

  def show
    room = Room.find(params[:id])
    today = Date.today

    reservations = Reservation.where(
      "room_id = ? AND (start_date >= ? AND end_date >= ?) AND status = ?",
      room.id, today, today, 1
    )

    unavaliable_dates = reservations.map{|res|
      (res[:start_date].to_datetime...res[:end_date].to_datetime).map {|day|
        day.strftime("%Y-%M-%D")
      }.flatten.to_set
    }

    calendars = Calendar.where(
      "room_id = ? AND status = ? AND day> = ?",
      room.id, 1, today
    ).pluck(:day).map(&:to_datetime).map {|day| day.strftime("%Y-%M-%D")}.flatten.to_set

    unavaliable_dates.merge calendars

    if !room.nil?
      room_serializer = RoomSerializer.new(
        room,
        image: room.cover_photo("medium"),
        avatar_url: room.user.image,
        unavaliable_dates: unavaliable_dates
      )
      render json: {room: room_serializer, is_success: true}, status: :ok
    else
      render json: {error: "Invalid ID", is_success: false}, status: 422
    end
  end
end
