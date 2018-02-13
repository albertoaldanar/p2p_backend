class RoomSerializer < ActiveModel::Serializer
  attributes  :id, :listing_name, :address,
              :home_type, :bed_room, :bath_room,
              :summary, :price, :acitve, :image, :unavailable_dates

  def unavaliable_dates
    @instance_options[:unavaliable_dates]
  end

  def image
    @instance_options[:image]
  end

  class UserSerializer < ActiveModel::Serializer
    attributes :email, :fullname, :image
  end
  belongs_to :user, serializer: UserSerializer, key: :host
end
