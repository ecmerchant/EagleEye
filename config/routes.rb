Rails.application.routes.draw do

  get 'prices/edit'
  post 'prices/edit'

  get 'lists/show'

  get 'list_templates/setup'
  post 'list_templates/setup'

  get 'products/search'
  post 'products/search'

  root to: 'products#search'

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
