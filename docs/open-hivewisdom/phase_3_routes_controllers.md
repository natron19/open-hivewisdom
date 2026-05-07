# Phase 3 — Routes & Controllers

**Goal:** Wire up all routes and build the three controllers with correct scoping and ownership enforcement. AI integration is stubbed (Gemini call not wired yet — that's Phase 5).

---

## 1. Routes

Add to `config/routes.rb`:

```ruby
resources :initiatives do
  resources :premortems, only: [:create, :show]
end

patch "/preventive_actions/:id/toggle", to: "preventive_actions#toggle", as: "toggle_preventive_action"
patch "/premortems/:id/reflection",     to: "premortems#update_reflection", as: "reflection_premortem"
```

This produces the named helpers used throughout the app:

```
initiatives_path                        GET    /initiatives
new_initiative_path                     GET    /initiatives/new
initiative_path(id)                     GET    /initiatives/:id
edit_initiative_path(id)                GET    /initiatives/:id/edit
initiative_premortems_path(initiative)  POST   /initiatives/:initiative_id/premortems
initiative_premortem_path(i, p)         GET    /initiatives/:initiative_id/premortems/:id
toggle_preventive_action_path(id)       PATCH  /preventive_actions/:id/toggle
reflection_premortem_path(id)           PATCH  /premortems/:id/reflection
```

---

## 2. InitiativesController

```ruby
# app/controllers/initiatives_controller.rb
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
```

**Scoping note:** `current_user.initiatives.find(params[:id])` raises `RecordNotFound` if the initiative belongs to a different user. The rescue renders 404, matching the boilerplate pattern for ownership enforcement.

---

## 3. PremortemsController

The `create` action in this phase renders a flash error (stub). Gemini integration is wired in Phase 5.

```ruby
# app/controllers/premortems_controller.rb
class PremortemsController < ApplicationController
  before_action :set_initiative

  def create
    # Phase 5 will replace this stub with the GeminiService call.
    redirect_to @initiative, alert: "Gemini integration coming in Phase 5."
  end

  def show
    @premortem = @initiative.premortems
                             .includes(failure_modes: :warning_signals, preventive_actions: [])
                             .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  def update_reflection
    @premortem = @initiative.premortems.find(params[:id])
    @premortem.update!(reflection: params[:reflection])
    render turbo_stream: turbo_stream.update(
      "premortem-reflection-#{@premortem.id}",
      partial: "premortems/reflection_saved"
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
```

---

## 4. PreventiveActionsController

```ruby
# app/controllers/preventive_actions_controller.rb
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
```

The ownership check here uses a JOIN rather than `current_user.initiatives`. This avoids needing the `initiative_id` in the URL and keeps the route clean at `/preventive_actions/:id/toggle`.

---

## 5. Ownership Enforcement Pattern

All three controllers follow the same pattern from the boilerplate:
- **Never return 403.** Always return 404 for any ownership check failure.
- **Scope through `current_user`** — never query a model directly without the user scope.
- The `require_authentication` before_action in `ApplicationController` handles unauthenticated redirects automatically.

---

## Acceptance Criteria

- `GET /initiatives` redirects to sign in when not authenticated
- Signed in: `GET /initiatives/new` renders the form (even before views are built — it will raise a missing template error at this phase, which is expected)
- Signed in: `POST /initiatives` with valid params creates the initiative and redirects
- Signed in as user B: `GET /initiatives/:user_a_initiative_id` returns 404
- `rails routes` shows all expected named helpers
