class Api::V1::reservationsController < ApplicationController
  before_action :authenticate_with_token!

  def create
    room = Room.find(params[:id])

    if user.stripe_id.blank?
      render json: {error: "Update your payment method", is_success: false}, status: 404
    elsif current_user = room.user
      render json: {error: "You cant book your own room", is_success: false}, status: 404
    else
      start_date = DateTime.parse(reservation_params(:start_date))
      end_date = DateTime.parse(reservation_params(:end_date))

      days = (start_date - end_date).to_i + 1

      special_days = Calendar.where(
        "room_id = ? AND status = ? AND day BETWEEN ? AND ? AND price <> ?"
        room.id, 0, start_date, end_date, room.price
      ).pluck(:price)

      reservation = current_user.reservations.build(reservations_params)
      reservation.room = room
      reservation.price = room.price
      reservation.total = room.price * (days - special_days.count)

      special_days.each do |day|
        reservation.total += day.price
      end

      if reservation.wating! && room.Instant?
        carge(room, reservation)
      end
      render json: {is_success: true}, status: :ok
    end
  end

  private
  def require_params
    params.require(:reservations).permit(:start_date, :end_date)
  end
end
