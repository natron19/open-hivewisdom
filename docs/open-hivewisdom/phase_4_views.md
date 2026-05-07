# Phase 4 — Views & Stimulus Controllers

**Goal:** Build all views and the two Stimulus controllers. Gemini output can be rendered using the seeded premortem from Phase 6 to test the accordion before live AI is wired up.

---

## 1. `initiatives/index.html.erb`

```erb
<div class="d-flex justify-content-between align-items-center mb-4">
  <h1 class="h3 mb-0">Your Initiatives</h1>
  <%= link_to "New Initiative", new_initiative_path, class: "btn btn-primary" %>
</div>

<% if @initiatives.any? %>
  <table class="table table-hover">
    <thead>
      <tr>
        <th>Name</th>
        <th>Time Horizon</th>
        <th>Premortems</th>
        <th>Latest Premortem</th>
        <th></th>
      </tr>
    </thead>
    <tbody>
      <% @initiatives.each do |initiative| %>
        <tr>
          <td><%= link_to initiative.name, initiative_path(initiative) %></td>
          <td><span class="badge bg-secondary"><%= initiative.time_horizon_label %></span></td>
          <td><%= initiative.premortems.count %></td>
          <td>
            <% if (latest = initiative.most_recent_premortem) %>
              <%= latest.created_at.strftime("%b %-d, %Y") %>
            <% else %>
              <span class="text-body-secondary small">None yet</span>
            <% end %>
          </td>
          <td class="text-end">
            <%= link_to "View", initiative_path(initiative), class: "btn btn-sm btn-outline-secondary" %>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
<% else %>
  <div class="alert alert-secondary">
    No initiatives yet.
    <%= link_to "Create your first initiative →", new_initiative_path %>
  </div>
<% end %>
```

---

## 2. `initiatives/new.html.erb`

```erb
<div class="row justify-content-center">
  <div class="col-lg-7">
    <h1 class="h3 mb-1">New Initiative</h1>
    <p class="text-body-secondary mb-4">Fill in five fields. The more specific, the sharper the premortem.</p>
    <%= render "form", initiative: @initiative %>
  </div>
</div>
```

---

## 3. `initiatives/edit.html.erb`

```erb
<div class="row justify-content-center">
  <div class="col-lg-7">
    <h1 class="h3 mb-1">Edit Initiative</h1>
    <p class="text-body-secondary mb-4">Editing does not invalidate past premortems — you can re-run with updated context.</p>
    <%= render "form", initiative: @initiative %>
  </div>
</div>
```

---

## 4. `initiatives/_form.html.erb`

```erb
<%= form_with model: initiative, class: "needs-validation" do |f| %>
  <% if initiative.errors.any? %>
    <div class="alert alert-danger">
      <strong>Please fix these errors:</strong>
      <ul class="mb-0 mt-1">
        <% initiative.errors.full_messages.each do |msg| %>
          <li><%= msg %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="mb-4">
    <%= f.label :name, "Initiative Name", class: "form-label fw-semibold" %>
    <%= f.text_field :name, class: "form-control", placeholder: "e.g. Quarterly roadmap review with the engineering team" %>
  </div>

  <div class="mb-4">
    <%= f.label :success_definition, "What does success look like?", class: "form-label fw-semibold" %>
    <%= f.text_area :success_definition, rows: 4, class: "form-control",
        placeholder: "In one paragraph, describe the end state you are aiming for." %>
  </div>

  <div class="mb-4" data-controller="segmented-button-group">
    <%= f.label :time_horizon, "Time Horizon", class: "form-label fw-semibold d-block" %>
    <div class="btn-group" role="group" aria-label="Time horizon">
      <% Initiative::TIME_HORIZONS.each do |horizon| %>
        <button type="button"
                class="btn btn-outline-secondary <%= 'active' if initiative.time_horizon == horizon %>"
                data-value="<%= horizon %>"
                data-action="click->segmented-button-group#select">
          <%= horizon.gsub("_", " ").capitalize %>
        </button>
      <% end %>
    </div>
    <%= f.hidden_field :time_horizon, data: { segmented_button_group_target: "field" },
        value: initiative.time_horizon.presence || "3_months" %>
  </div>

  <div class="mb-4">
    <%= f.label :current_state, "Where is this work today?", class: "form-label fw-semibold" %>
    <%= f.text_area :current_state, rows: 4, class: "form-control",
        placeholder: "Describe where the initiative stands right now: what has been done, what is blocked, what is unclear." %>
  </div>

  <div class="mb-4">
    <%= f.label :team_context, "Who is involved?", class: "form-label fw-semibold" %>
    <%= f.text_area :team_context, rows: 3, class: "form-control",
        placeholder: "Describe the team: roles, history, any known friction. Avoid naming specific individuals." %>
    <div class="form-text text-body-secondary">
      Avoid pasting names or identifying details of specific team members. Describe roles instead.
    </div>
  </div>

  <div class="d-flex gap-2">
    <%= f.submit initiative.new_record? ? "Save Initiative" : "Update Initiative",
        class: "btn btn-primary" %>
    <%= link_to "Cancel", initiative.new_record? ? initiatives_path : initiative_path(initiative),
        class: "btn btn-outline-secondary" %>
  </div>

<% end %>
```

---

## 5. `initiatives/show.html.erb`

```erb
<div class="d-flex justify-content-between align-items-start mb-4">
  <div>
    <h1 class="h3 mb-1"><%= @initiative.name %></h1>
    <span class="badge bg-secondary"><%= @initiative.time_horizon_label %></span>
  </div>
  <%= link_to "Edit", edit_initiative_path(@initiative), class: "btn btn-sm btn-outline-secondary" %>
</div>

<%# Initiative summary %>
<div class="card mb-4">
  <div class="card-body">
    <div class="row g-4">
      <div class="col-md-6">
        <p class="text-body-secondary small mb-1 fw-semibold">What success looks like</p>
        <p class="mb-0"><%= @initiative.success_definition %></p>
      </div>
      <div class="col-md-6">
        <p class="text-body-secondary small mb-1 fw-semibold">Current state</p>
        <p class="mb-0"><%= @initiative.current_state %></p>
      </div>
      <div class="col-12">
        <p class="text-body-secondary small mb-1 fw-semibold">Team context</p>
        <p class="mb-0"><%= @initiative.team_context %></p>
      </div>
    </div>
  </div>
</div>

<%# Premortem section (Turbo Frame) %>
<%= turbo_frame_tag "premortem-frame-#{@initiative.id}" do %>
  <% if @premortem %>
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h4 class="mb-0">Premortem</h4>
      <div class="d-flex gap-2 align-items-center">
        <span class="text-body-secondary small">Run <%= @premortem.created_at.strftime("%b %-d, %Y") %></span>
        <%= button_to "Re-run Premortem", initiative_premortems_path(@initiative),
            class: "btn btn-sm btn-outline-secondary",
            data: { turbo_confirm: "Replace the current premortem with a new one?" } %>
      </div>
    </div>
    <%= render "premortem", premortem: @premortem %>
  <% else %>
    <div class="card text-center py-5">
      <div class="card-body">
        <h5 class="card-title">Ready to run the premortem?</h5>
        <p class="card-text text-body-secondary">Imagine this initiative has already failed. Find out why.</p>
        <%= button_to "Run Premortem", initiative_premortems_path(@initiative),
            class: "btn btn-primary btn-lg px-5" %>
      </div>
    </div>
  <% end %>
<% end %>

<% if @initiative.premortems.count > 1 %>
  <div class="mt-4">
    <h6 class="text-body-secondary">Previous premortems</h6>
    <% @initiative.premortems.offset(1).each do |p| %>
      <%= link_to p.created_at.strftime("%b %-d, %Y"), initiative_premortem_path(@initiative, p),
          class: "badge bg-secondary text-decoration-none me-1" %>
    <% end %>
  </div>
<% end %>
```

---

## 6. `initiatives/_premortem.html.erb`

This is the main output partial. It expects `premortem` to be passed as a local.

```erb
<%# 1. Imagined Failure Date banner %>
<div class="card failure-date-banner mb-4">
  <div class="card-body text-center py-4">
    <p class="text-body-secondary mb-1 small">By this date, this initiative has failed because&hellip;</p>
    <div class="display-6 fw-bold" style="color: var(--accent);">
      <%= premortem.imagined_failure_date&.strftime("%B %-d, %Y") %>
    </div>
  </div>
</div>

<%# 2. Failure modes accordion %>
<h5 class="mb-3">Top 5 Failure Modes</h5>
<div class="accordion mb-4" id="failure-modes-<%= premortem.id %>">
  <% premortem.failure_modes.each do |fm| %>
    <div class="accordion-item">
      <h2 class="accordion-header">
        <button class="accordion-button <%= fm.rank == 1 ? '' : 'collapsed' %>"
                type="button"
                data-bs-toggle="collapse"
                data-bs-target="#fm-<%= fm.id %>"
                aria-expanded="<%= fm.rank == 1 ? 'true' : 'false' %>">
          <span class="fw-semibold me-3 text-body-secondary">#<%= fm.rank %></span>
          <%= fm.statement %>
          <span class="badge <%= fm.severity_badge_class %> ms-3 flex-shrink-0"><%= fm.severity.capitalize %></span>
        </button>
      </h2>
      <div id="fm-<%= fm.id %>"
           class="accordion-collapse collapse <%= fm.rank == 1 ? 'show' : '' %>"
           data-bs-parent="#failure-modes-<%= premortem.id %>">
        <div class="accordion-body">
          <p class="fst-italic text-body-secondary mb-3">
            <strong>Assumption that breaks:</strong> <%= fm.assumption %>
          </p>
          <p class="small fw-semibold text-body-secondary mb-2">Early Warning Signals</p>
          <ul class="list-unstyled">
            <% fm.warning_signals.each do |ws| %>
              <li class="mb-2">
                <span class="fw-semibold"><%= ws.signal %></span>
                <div class="small text-body-secondary"><em>How to observe:</em> <%= ws.measurement_method %></div>
              </li>
            <% end %>
          </ul>
        </div>
      </div>
    </div>
  <% end %>
</div>

<%# 3. Preventive actions checklist %>
<h5 class="mb-3">Preventive Actions This Week</h5>
<div class="list-group mb-4">
  <% premortem.preventive_actions.each do |action| %>
    <%= render "preventive_action", action: action %>
  <% end %>
</div>

<%# 4. Avoided truth callout %>
<div class="card avoided-truth-card mb-4">
  <div class="card-body">
    <p class="small text-body-secondary fw-semibold mb-2">The Avoided Truth</p>
    <p class="fst-italic mb-2"><%= premortem.avoided_truth %></p>
    <p class="small text-body-secondary mb-0">
      These are AI-generated hypotheses, not predictions. Treat them as starting points for your team's discussion, not conclusions.
    </p>
  </div>
</div>

<%# 5. Reflection %>
<div id="premortem-reflection-<%= premortem.id %>">
  <%= render "reflection", premortem: premortem %>
</div>

<%# 6. Raw response toggle %>
<div class="mt-4">
  <button class="btn btn-sm btn-outline-secondary"
          type="button"
          data-bs-toggle="collapse"
          data-bs-target="#raw-response-<%= premortem.id %>">
    Show raw response (what the AI actually returned)
  </button>
  <div id="raw-response-<%= premortem.id %>" class="collapse mt-2">
    <pre class="p-3 border rounded small text-body-secondary" style="overflow-x: auto; white-space: pre-wrap;"><%= premortem.gemini_raw %></pre>
  </div>
</div>
```

---

## 7. `initiatives/_preventive_action.html.erb`

This partial is rendered by the accordion and updated by the Turbo Stream toggle.

```erb
<div id="preventive-action-<%= action.id %>"
     class="list-group-item d-flex align-items-start gap-3">
  <%= button_to toggle_preventive_action_path(action),
      method: :patch,
      class: "btn p-0 border-0 mt-1 flex-shrink-0",
      form: { data: { turbo_stream: true } } do %>
    <% if action.started %>
      <span class="fs-5">☑</span>
    <% else %>
      <span class="fs-5 text-body-secondary">☐</span>
    <% end %>
  <% end %>

  <div class="flex-grow-1 <%= 'preventive-started' if action.started %>">
    <%= action.description %>
  </div>

  <% if action.high_leverage? %>
    <span class="badge bg-warning text-dark flex-shrink-0" title="High leverage">⚡ <%= action.effectiveness_to_effort %>/5</span>
  <% else %>
    <span class="badge bg-secondary flex-shrink-0"><%= action.effectiveness_to_effort %>/5</span>
  <% end %>
</div>
```

---

## 8. `initiatives/_reflection.html.erb` and `premortems/_reflection_saved.html.erb`

**The editable state** (`initiatives/_reflection.html.erb`, also used as `premortems/_reflection.html.erb`):

```erb
<h6 class="mb-2">Your Reflection</h6>
<%= form_with url: reflection_premortem_path(premortem), method: :patch,
    data: { turbo_stream: true } do |f| %>
  <%= f.text_area :reflection, value: premortem.reflection,
      rows: 3, class: "form-control mb-2",
      placeholder: "Add a note after reading this premortem — what resonates, what you'd push back on." %>
  <%= f.submit "Save Reflection", class: "btn btn-sm btn-outline-secondary" %>
<% end %>
```

**The saved state** (`app/views/premortems/_reflection_saved.html.erb`):

```erb
<h6 class="mb-2">Your Reflection</h6>
<div class="border rounded p-3 text-body-secondary">
  <%= premortem.reflection.presence || "No reflection saved." %>
</div>
<span class="badge bg-success mt-2">Saved</span>
```

---

## 9. `premortems/show.html.erb`

For viewing a historical premortem (not the most recent one on the show page):

```erb
<div class="mb-3">
  <%= link_to "← Back to #{@initiative.name}", initiative_path(@initiative), class: "small" %>
</div>

<div class="d-flex justify-content-between align-items-start mb-4">
  <div>
    <h1 class="h3 mb-1">Premortem</h1>
    <p class="text-body-secondary small">Recorded <%= @premortem.created_at.strftime("%B %-d, %Y") %></p>
  </div>
</div>

<div class="card mb-4">
  <div class="card-body">
    <p class="text-body-secondary small fw-semibold mb-1">Initiative</p>
    <p class="mb-0 fw-semibold"><%= @initiative.name %></p>
  </div>
</div>

<%= render "initiatives/premortem", premortem: @premortem %>
```

---

## 10. Stimulus Controllers

### `segmented_button_group_controller.js`

Manages the time horizon button group. Exactly one button is active at a time; the hidden field gets the active button's value.

```javascript
// app/javascript/controllers/segmented_button_group_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field"]

  select(event) {
    const clicked = event.currentTarget
    this.element.querySelectorAll("button[data-value]").forEach(btn => {
      btn.classList.toggle("active", btn === clicked)
    })
    this.fieldTarget.value = clicked.dataset.value
  }
}
```

### `preventive_action_toggle_controller.js`

Not needed as a custom Stimulus controller — the toggle uses `button_to` with `data: { turbo_stream: true }`, which Turbo handles natively. The partial re-render comes back as a Turbo Stream `update`. No custom JS needed.

If for any reason the native Turbo approach doesn't work, a minimal fallback:

```javascript
// app/javascript/controllers/preventive_action_toggle_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Native Turbo handles the form submit — this controller is a placeholder
    // in case per-item state needs to be tracked locally.
  }
}
```

---

## Acceptance Criteria

- `GET /initiatives/new` renders the form with all five fields
- Time horizon segmented buttons: clicking "6 months" highlights it and updates the hidden field value (verify in browser devtools)
- Form validation errors render correctly (submit empty form, verify error list appears)
- `GET /initiatives/:id` shows the initiative summary card and "Run Premortem" CTA when no premortem exists
- `GET /initiatives/:id` with a seeded premortem shows the full accordion (requires Phase 6 seed data)
- Accordion first item is open by default; others are collapsed
- Raw response collapse toggle reveals the `gemini_raw` JSON
