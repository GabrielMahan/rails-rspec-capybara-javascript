require 'rails_helper'

feature 'JavaScript messages' do
  let(:text) { 'This is the test message!' }
  let!(:message) { Message.create(text: text) }

  scenario 'User views the home page' do
    visit '/'
    expect(page).to have_content text
  end
end