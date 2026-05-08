class InitiativesController < ApplicationController
  before_action :set_initiative, only: [:show, :edit, :update, :destroy, :markdown_export]

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

  def markdown_export
    premortem = @initiative.premortems
                            .includes(failure_modes: :warning_signals, preventive_actions: [])
                            .first
    markdown = build_markdown(@initiative, premortem)
    filename = "#{@initiative.name.parameterize}-premortem-#{Date.today}.md"
    send_data markdown, filename: filename, type: "text/plain", disposition: "attachment"
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

  def build_markdown(initiative, premortem)
    lines = []
    lines << "# #{initiative.name}"
    lines << ""
    lines << "**Time horizon:** #{initiative.time_horizon_label}"
    lines << ""
    lines << "## What Success Looks Like"
    lines << ""
    lines << initiative.success_definition
    lines << ""
    lines << "## Current State"
    lines << ""
    lines << initiative.current_state
    lines << ""
    lines << "## Team Context"
    lines << ""
    lines << initiative.team_context
    lines << ""

    return lines.join("\n") unless premortem

    lines << "---"
    lines << ""
    lines << "## Premortem — #{premortem.created_at.strftime("%B %-d, %Y")}"
    lines << ""
    lines << "**Imagined failure date:** #{premortem.imagined_failure_date&.strftime("%B %-d, %Y")}"
    lines << ""
    lines << "### Top 5 Failure Modes"
    lines << ""
    premortem.failure_modes.each do |fm|
      lines << "#### \##{fm.rank} — #{fm.statement} [#{fm.severity.upcase}]"
      lines << ""
      lines << "**Assumption that breaks:** #{fm.assumption}"
      lines << ""
      unless fm.warning_signals.empty?
        lines << "**Early Warning Signals:**"
        lines << ""
        fm.warning_signals.each do |ws|
          lines << "- **#{ws.signal}** — *How to observe:* #{ws.measurement_method}"
        end
        lines << ""
      end
    end

    lines << "### Preventive Actions This Week"
    lines << ""
    premortem.preventive_actions.each do |action|
      checkbox = action.started ? "[x]" : "[ ]"
      leverage = action.high_leverage? ? " ⚡" : ""
      lines << "- #{checkbox} #{action.description} (#{action.effectiveness_to_effort}/5#{leverage})"
    end
    lines << ""

    lines << "### The Avoided Truth"
    lines << ""
    lines << premortem.avoided_truth
    lines << ""

    if premortem.reflection.present?
      lines << "### Reflection"
      lines << ""
      lines << premortem.reflection
      lines << ""
    end

    lines.join("\n")
  end
end
