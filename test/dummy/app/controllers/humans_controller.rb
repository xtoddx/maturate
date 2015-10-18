class HumansController < ApplicationController
  skip_versioned_url_generation only: [:index2]

  def index
    render text: 'OK', location: humans_path
  end

  def index2
    render text: 'FINE', location: benefits_packages_path
  end
end
