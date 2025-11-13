module ApplicationHelper
  include Pagy::Frontend

  def pagination_nav(pagy, item_name: nil)
    return unless pagy

    render "shared/pagination", pagy:, item_name:
  end
end
