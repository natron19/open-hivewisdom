class PremortemsController < ApplicationController
  before_action :set_initiative, only: [:create, :show]
  rate_limit to: 5, within: 1.minute, only: [:create],
             with: -> { redirect_to @initiative, alert: "Please wait before running another premortem." }

  def create
    raw = GeminiService.generate(
      template:  "hivewisdom_premortem_v1",
      variables: {
        initiative_name:    @initiative.name,
        success_definition: @initiative.success_definition,
        time_horizon:       @initiative.time_horizon,
        current_state:      @initiative.current_state,
        team_context:       @initiative.team_context
      }
    )

    data = PremortemParser.new(raw).parse!

    ActiveRecord::Base.transaction do
      pm = @initiative.premortems.create!(
        imagined_failure_date: Date.parse(data["imagined_failure_date"]),
        avoided_truth:         data["avoided_truth"],
        gemini_raw:            raw
      )

      data["failure_modes"].each do |fm_data|
        fm = pm.failure_modes.create!(
          rank:       fm_data["rank"],
          statement:  fm_data["statement"],
          severity:   fm_data["severity"],
          assumption: fm_data["assumption"]
        )
        fm_data["warning_signals"].each do |ws_data|
          fm.warning_signals.create!(
            signal:             ws_data["signal"],
            measurement_method: ws_data["measurement_method"]
          )
        end
      end

      data["preventive_actions"].each do |pa_data|
        pm.preventive_actions.create!(
          rank:                    pa_data["rank"],
          description:             pa_data["description"],
          effectiveness_to_effort: pa_data["effectiveness_to_effort"]
        )
      end
    end

    redirect_to @initiative, notice: "Premortem complete."

  rescue GeminiService::BudgetExceededError
    render turbo_stream: turbo_stream.update(
      "premortem-frame-#{@initiative.id}",
      partial: "shared/ai_error",
      locals: { error_type: :budget_exceeded, retry_path: initiative_path(@initiative) }
    )
  rescue GeminiService::GatekeeperError
    render turbo_stream: turbo_stream.update(
      "premortem-frame-#{@initiative.id}",
      partial: "shared/ai_error",
      locals: { error_type: :gatekeeper_blocked, retry_path: initiative_path(@initiative) }
    )
  rescue GeminiService::TimeoutError
    render turbo_stream: turbo_stream.update(
      "premortem-frame-#{@initiative.id}",
      partial: "shared/ai_error",
      locals: { error_type: :timeout, retry_path: initiative_path(@initiative) }
    )
  rescue GeminiService::GeminiError
    render turbo_stream: turbo_stream.update(
      "premortem-frame-#{@initiative.id}",
      partial: "shared/ai_error",
      locals: { error_type: :error, retry_path: initiative_path(@initiative) }
    )
  end

  def show
    @premortem = @initiative.premortems
                             .includes(failure_modes: :warning_signals, preventive_actions: [])
                             .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  def update_reflection
    @premortem = Premortem
                   .joins(initiative: :user)
                   .where(users: { id: current_user.id })
                   .find(params[:id])
    @premortem.update!(reflection: params[:reflection])
    render turbo_stream: turbo_stream.update(
      "premortem-reflection-#{@premortem.id}",
      partial: "premortems/reflection_saved",
      locals: { premortem: @premortem }
    )
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  private

  def set_initiative
    @initiative = current_user.initiatives.find(params[:initiative_id])
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end
end
