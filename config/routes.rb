GedViz::Application.routes.draw do

  # Presentation JSON/CSV interface
  resources :presentations, only: [:new, :show, :create] do
    get 'export', on: :member
  end

  # Translations
  get 'translations' => 'application#translations'

  # Saving JavaScript exceptions
  post 'javascript_exceptions' => 'javascript_exceptions#create'

  # Player
  get ':id' => 'presentations#show', as: 'player', constraints: { id: /\d+/ }

  # Keyframe query interface
  post 'keyframes/query' => 'keyframes#query'

  # Country query interface
  post 'countries/sort'     => 'countries#sort'
  post 'countries/partners' => 'countries#partners'

  # Editor
  get 'edit/:id(/:index)' => 'presentations#edit',
    as: 'editor',
    constraints: {
      id: /\d+/
    }

  # Keyframe thumbnails
  get 'system/static/:id/keyframe_:keyframe(_:size).png' => 'keyframes#static',
    as: 'static',
    format: false,
    defaults: {size: 'large'},
    constraints: {
      keyframe: /\d+/,
      size: /large|medium|small|thumb/
    }

  # Static chart for PNG rendering
  get 'render/:presentation_id(/:keyframe)' => 'keyframes#render_chart',
      as: 'render',
      constraints: {
        id: /\d+/
      }

  root :to => 'presentations#new'

end
