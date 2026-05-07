class PreventiveActionsController < ApplicationController
  def toggle
    @action = PreventiveAction
                .joins(premortem: { initiative: :user })
                .where(users: { id: current_user.id })
                .find(params[:id])
    @action.update!(started: !@action.started)
    render turbo_stream: turbo_stream.update(
      "preventive-action-#{@action.id}",
      partial: "initiatives/preventive_action",
      locals: { action: @action }
    )
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end
end
