require 'resque/server'

Rails.application.routes.draw do

  get 'prices/edit'
  post 'prices/edit'

  get 'lists/show'

  get 'list_templates/setup'
  post 'list_templates/setup'

  get 'products/search'
  post 'products/search'
  get 'products/setup'
  post 'products/setup'
  post 'products/delete'

  root to: 'products#search'

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  mount Resque::Server.new, at: "/resque"

  devise_scope :user do
    get '/users/sign_out' => 'devise/sessions#destroy'
    get '/sign_in' => 'devise/sessions#new'
  end

  devise_for :users, :controllers => {
   :registrations => 'users/registrations'
  }

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
