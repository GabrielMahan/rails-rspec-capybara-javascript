class MessagesController < ApplicationController

  def show
    @message = Message.first
  end

end