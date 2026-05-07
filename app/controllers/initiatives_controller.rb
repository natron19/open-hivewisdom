class InitiativesController < ApplicationController
  before_action :set_initiative, only: [:show, :edit, :update, :destroy]

  def index
    @initiatives = current_user.initiatives.recent
  end

  def new
    @initiative = current_user.initiatives.build
  end

  def create
    @initiative = current_user.initiatives.build(initiative_params)
    if @initiative.save
      redirect_to @initiative, notice: "Initiative saved. Run a premortem to see how it could fail."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @premortem = @initiative.premortems
                             .includes(failure_modes: :warning_signals, preventive_actions: [])
                             .first
  end

  def edit; end

  def update
    if @initiative.update(initiative_params)
      redirect_to @initiative, notice: "Initiative updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @initiative.destroy
    redirect_to initiatives_path, notice: "Initiative deleted."
  end

  private

  def set_initiative
    @initiative = current_user.initiatives.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  def initiative_params
    params.require(:initiative).permit(:name, :success_definition, :time_horizon, :current_state, :team_context)
  end
end
