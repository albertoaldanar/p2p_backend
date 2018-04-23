class Api::V1::reservationsController < ApplicationController
  before_action :authenticate_with_token!
  before_action :set_reservation, only: [:approved, :declinded]

  def create
    room = Room.find(params[:room_id])
    user = current_user

    if user.stripe_id.blank?
      render json: {error: "Update your payment method", is_success: false}, status: 404
    elsif user == room.user
      render json: {error: "You cant book your own room", is_success: false}, status: 404
    else
      start_date = DateTime.parse(reservation_params[:start_date])
      end_date = DateTime.parse(reservation_params[:end_date])

      days = (start_date - end_date).to_i + 1

      special_days = Calendar.where(
        "room_id = ? AND status = ? AND day BETWEEN ? AND ? AND price <> ?"
        room.id, 0, start_date, end_date, room.price
      ).pluck(:price)

      reservation = current_user.reservations.build(reservation_params)
      reservation.room = room
      reservation.price = room.price
      reservation.total = room.price * (days - special_days.count)

      special_days.each do |day|
        reservation.total += day.price
      end

      if reservation.Waiting! && room.Instant?
        charge(room, reservation)
      end

      render json: { is_success: true }, status: :ok
    end
  end

  def reservations_by_room
    reservations = Reservation.where(room_id: params[:id])
    reservations = reservations.map do | res |
      ReservationSerializer.new(res, avatar_url: res.user.image)
    end
    render json: {reservations: reservations, is_success: true }, status: :ok
  end

  def approved
    if @reservation.room.user_id == current_user.id
      charge(@reservation.room, @reservation)
      render json: { is_success: true }, status: :ok
    else
      render json: { error: "No permission", is_success: false }, status: 422
    end

  end

  def declined
    if @reservation.room.user_id == current_user.id
      @reservation.Declined
      render json: { is_success: true }, status: :ok
    else
      render json: { error: "No permission", is_success: false }, status: 422
    end
  end

  private

  def require_params
    params.require(:reservations).permit(:start_date, :end_date)
  end

  def set_reservation
    @reservation = Reservation.find(params[:id])
  end

  def charge(room, reservation)
    if !reservation.user.stripe_id.blank? && !room.user.merchant_id.blank?
      customer = Stripe::Customer.retrive(reservation.user.stripe_id)
      charge = Stripe::Charge.create(
        :customer => customer.id,
        :amount => reservation.total * 100,
        :description => room.listing_name,
        :currency => "usd",
        :destination => {
          :amount => reservation.total * 80,
          :account => room.user.merchant_id
        }
      )
      if charge
        reservation.Approved!
      else
        reservation.Declined!
      end
    end
  rescue Stripe::CardError => e
    reservation.Declined!
    render json: {error: e.message, is_success: false}, status: 404
  end
 end
