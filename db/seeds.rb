# Admin user — credentials for local demo use only
User.find_or_create_by!(email: "demo@example.com") do |u|
  u.name                  = "Demo User"
  u.password              = "password123"
  u.password_confirmation = "password123"
  u.admin                 = true
end

puts "Demo user: demo@example.com / password123"

# Health ping template — used by /up/llm
AiTemplate.find_or_initialize_by(name: "health_ping").tap do |t|
  t.description          = "Minimal prompt used by the /up/llm health check endpoint."
  t.system_prompt        = "You are a health check endpoint. Respond with exactly: ok"
  t.user_prompt_template = "ping"
  t.model                = "gemini-2.5-flash"
  t.max_output_tokens    = 10
  t.temperature          = 0.0
  t.notes                = "Do not modify. Used by HealthController#llm."
  t.save!
end

puts "Seeded: health_ping AI template"

AiTemplate.find_or_initialize_by(name: "hivewisdom_premortem_v1").tap do |t|
  t.description = "Runs a structured premortem on a user-described initiative. Returns five ranked failure modes with warning signals and a ranked list of preventive actions."
  t.model = "gemini-2.5-flash"
  t.max_output_tokens = 8192
  t.temperature = 0.6

  t.system_prompt = <<~PROMPT.strip
    You are a foresight practitioner running a premortem on an initiative the user is about to commit to. Your job is to imagine that the initiative has already failed and to reconstruct, plausibly, why it failed.

    You will not hedge. You will not soften. You will not tell the user the initiative sounds promising. The user already knows the optimistic case; that is why they brought it to you. They are paying for the pessimistic, structured first draft they cannot easily produce on their own.

    Your output is the analysis a thoughtful skeptic would write after a half-hour reading the brief. It is specific, falsifiable where possible, and grounded in the user's own context (the team, the time horizon, the current state). It does not invoke generic startup failure modes that could apply to any initiative.

    You produce JSON only. No prose preamble, no closing remarks, no markdown fences around the JSON. The schema is provided in the user prompt; deviating from it breaks the application.

    You will populate every field. If a field is hard to fill, fill it with your best plausible guess rather than leaving it empty. The user will calibrate what is useful and what is noise.

    You will name the one uncomfortable truth the team is probably avoiding. This is the highest-leverage item in your output. It is usually a relationship, a missing skill, an unspoken disagreement, or a structural constraint that nobody wants to surface in a planning meeting. If everything else in your output is correct but this field is bland, your output has failed.
  PROMPT

  t.user_prompt_template = <<~PROMPT.strip
    Run a premortem on the following initiative. Imagine you are looking back from the failure date you choose; the initiative has failed; you are explaining why.

    INITIATIVE NAME:
    {{initiative_name}}

    WHAT SUCCESS LOOKS LIKE:
    {{success_definition}}

    TIME HORIZON:
    {{time_horizon}}

    CURRENT STATE OF THE WORK:
    {{current_state}}

    TEAM AND COMMUNITY INVOLVED:
    {{team_context}}

    Return JSON only, no markdown fences, conforming exactly to this schema:

    {
      "imagined_failure_date": "YYYY-MM-DD (a specific date by which it has become clear this initiative failed; choose a date inside the time horizon)",
      "failure_modes": [
        {
          "rank": 1,
          "statement": "One sentence describing how this initiative failed.",
          "severity": "low | medium | high",
          "assumption": "The assumption baked into the current plan that would have to break for this failure to occur.",
          "warning_signals": [
            {
              "signal": "An observable thing the team could see in the weeks before the failure becomes obvious.",
              "measurement_method": "How the team would actually observe or measure this signal."
            }
          ]
        }
      ],
      "preventive_actions": [
        {
          "rank": 1,
          "description": "A specific action the team could take this week.",
          "effectiveness_to_effort": 1
        }
      ],
      "avoided_truth": "One sentence naming the uncomfortable truth most premortems for an initiative like this would skip past."
    }

    Constraints:
    - Exactly 5 entries in failure_modes, ranked 1 (most likely) through 5
    - Each failure_mode contains 2 or 3 warning_signals
    - Between 5 and 7 entries in preventive_actions, ranked 1 (highest leverage) through N
    - effectiveness_to_effort is an integer from 1 (low leverage) to 5 (high leverage)
    - avoided_truth is exactly one sentence
    - All fields populated, no nulls
  PROMPT

  t.notes = <<~NOTES.strip
    This template is the heart of the demo. The system prompt enforces the JSON contract and pushes the model away from default-helpful blandness toward something a real foresight practitioner would write.

    The model occasionally returns JSON inside a markdown code fence despite instructions. PremortemParser strips fences before parsing.

    Watch for too-generic warning signals. If they occur, lower temperature to 0.5 and re-test in the admin panel.

    The avoided_truth being a platitude is a prompt quality issue. The system prompt's last paragraph addresses this directly.
  NOTES
  t.save!
end

puts "Seeded: hivewisdom_premortem_v1 AI template"

# ─── Domain seed data ──────────────────────────────────────────────────────────

demo_user = User.find_by!(email: "demo@example.com")

# Initiative 1 — with a full seeded premortem (no API call needed)
initiative1 = Initiative.find_or_create_by!(user: demo_user, name: "Quarterly product roadmap review with the engineering team") do |i|
  i.time_horizon = "3_months"
  i.success_definition = <<~TEXT.strip
    We have reached alignment on the next two major releases: one shipping in six weeks, one in twelve weeks. The engineering team has agreed to cut one in-progress project that is stalled. Each team member can describe the top priority without looking at the doc.
  TEXT
  i.current_state = <<~TEXT.strip
    The backlog has 34 open items. Three have been in progress for more than three months. The engineering lead and the product lead have different mental models of what the Q3 release will contain, though neither has said so explicitly in a meeting. We have a roadmap doc that was last updated two months ago.
  TEXT
  i.team_context = <<~TEXT.strip
    Four people: a product lead, an engineering lead, and two engineers. One engineer joined six weeks ago and has not yet shipped anything. The previous engineer left abruptly after a disagreement with the engineering lead. The team has been heads-down and has not done a structured planning session in four months.
  TEXT
end

if initiative1.premortems.none?
  failure_date = Date.today + 90.days

  seeded_raw = JSON.generate(
    imagined_failure_date: failure_date.iso8601,
    avoided_truth: "The product lead and engineering lead have fundamentally different ideas about what this roadmap is for — one sees it as a commitment, the other as a starting point for negotiation — and nobody has named that difference in a meeting.",
    failure_modes: [
      { rank: 1, severity: "high",
        statement: "The meeting ends with a list of items that everyone nodded at but nobody is accountable for, and the same backlog exists three months later.",
        assumption: "Attendance at a planning meeting converts to ownership of specific commitments.",
        warning_signals: [
          { signal: "Action items from the meeting have no assigned owner and no deadline.", measurement_method: "Review the meeting notes 48 hours after the session; flag any item without a name next to it." },
          { signal: "The 'cut' project reappears on a sprint board within two weeks.", measurement_method: "Check the project tracker weekly for the first month." }
        ] },
      { rank: 2, severity: "high",
        statement: "The product lead and engineering lead reach surface agreement in the room but immediately begin pursuing different roadmap interpretations in their own work streams.",
        assumption: "Agreement in a meeting room persists when participants return to their desks and their own priorities.",
        warning_signals: [
          { signal: "Engineering begins work on a feature that product has not prioritized.", measurement_method: "Compare sprint commits to the agreed roadmap at the two-week mark." },
          { signal: "The product lead starts scoping a feature the engineering lead thinks is already cut.", measurement_method: "Weekly five-minute check-in between the two leads on current active work." }
        ] },
      { rank: 3, severity: "medium",
        statement: "The new engineer, whose context on the codebase is incomplete, is assigned to lead the cut decision for the stalled project and delays it by asking for more information.",
        assumption: "A six-week-tenured engineer has enough context to make a confident prioritization call.",
        warning_signals: [
          { signal: "The engineer sends a second round of clarifying questions after the first has been answered.", measurement_method: "Track the number of information-gathering rounds on the cut decision." },
          { signal: "The stalled project remains in 'in progress' status two weeks after the roadmap review.", measurement_method: "Check the project tracker status column." }
        ] },
      { rank: 4, severity: "medium",
        statement: "The session fills its two-hour slot with status updates rather than decisions, and the team runs out of time before addressing the cut project.",
        assumption: "A two-hour meeting with four attendees and 34 backlog items can reach decisions without a structured agenda enforced by a facilitator.",
        warning_signals: [
          { signal: "The first forty-five minutes are consumed by one engineer walking through their work.", measurement_method: "Track time spent on each agenda item; flag if any single item exceeds twenty minutes." },
          { signal: "The cut project is item twelve on the agenda.", measurement_method: "Review the agenda before the meeting; cut decision should be item one or two." }
        ] },
      { rank: 5, severity: "low",
        statement: "The roadmap document that emerges from the session is written at a level of abstraction that means different things to different readers, so apparent alignment dissolves when implementation begins.",
        assumption: "A shared vocabulary for what 'release' and 'cut' mean exists among the four team members.",
        warning_signals: [
          { signal: "Two people describe the same roadmap item with different scope when asked separately.", measurement_method: "After the meeting, ask each team member to describe the top priority in one sentence without looking at the doc. Compare." },
          { signal: "The doc uses phrases like 'approximately', 'as time allows', or 'scope TBD'.", measurement_method: "Review the final doc for hedging language before it is shared outside the team." }
        ] }
    ],
    preventive_actions: [
      { rank: 1, effectiveness_to_effort: 5, description: "Before the session, have the product lead and engineering lead each write down independently what the outcome of this roadmap review will be in one paragraph. Share and compare before the meeting starts." },
      { rank: 2, effectiveness_to_effort: 5, description: "Name the stalled project explicitly at the top of the agenda as a forced choice: cut, complete in two weeks, or hand to an outside contractor. Remove it from discussion until a decision is made." },
      { rank: 3, effectiveness_to_effort: 4, description: "Assign a facilitator (not the product or engineering lead) who is responsible only for keeping time and surfacing disagreement. The new engineer is a reasonable choice." },
      { rank: 4, effectiveness_to_effort: 4, description: "End the session with each team member stating in one sentence what they are personally responsible for shipping in the next six weeks. Write it on the shared doc in front of everyone." },
      { rank: 5, effectiveness_to_effort: 3, description: "Schedule a thirty-minute check-in two weeks after the roadmap session to confirm the cut project has not re-entered the backlog and that work matches the stated priorities." },
      { rank: 6, effectiveness_to_effort: 3, description: "Replace the existing roadmap doc with a simple two-column table: what ships in six weeks, what ships in twelve weeks. No other items. Archive the 34-item backlog separately." },
      { rank: 7, effectiveness_to_effort: 2, description: "Pair the new engineer with the engineering lead for the first two weeks post-roadmap to accelerate context transfer and reduce information-gathering delays on implementation decisions." }
    ]
  )

  pm = initiative1.premortems.create!(
    imagined_failure_date: failure_date,
    avoided_truth: "The product lead and engineering lead have fundamentally different ideas about what this roadmap is for — one sees it as a commitment, the other as a starting point for negotiation — and nobody has named that difference in a meeting.",
    gemini_raw: seeded_raw
  )

  [
    { rank: 1, severity: "high",
      statement: "The meeting ends with a list of items that everyone nodded at but nobody is accountable for, and the same backlog exists three months later.",
      assumption: "Attendance at a planning meeting converts to ownership of specific commitments.",
      signals: [
        { signal: "Action items from the meeting have no assigned owner and no deadline.", measurement_method: "Review the meeting notes 48 hours after the session; flag any item without a name next to it." },
        { signal: "The 'cut' project reappears on a sprint board within two weeks.", measurement_method: "Check the project tracker weekly for the first month." }
      ] },
    { rank: 2, severity: "high",
      statement: "The product lead and engineering lead reach surface agreement in the room but immediately begin pursuing different roadmap interpretations in their own work streams.",
      assumption: "Agreement in a meeting room persists when participants return to their desks and their own priorities.",
      signals: [
        { signal: "Engineering begins work on a feature that product has not prioritized.", measurement_method: "Compare sprint commits to the agreed roadmap at the two-week mark." },
        { signal: "The product lead starts scoping a feature the engineering lead thinks is already cut.", measurement_method: "Weekly five-minute check-in between the two leads on current active work." }
      ] },
    { rank: 3, severity: "medium",
      statement: "The new engineer, whose context on the codebase is incomplete, is assigned to lead the cut decision for the stalled project and delays it by asking for more information.",
      assumption: "A six-week-tenured engineer has enough context to make a confident prioritization call.",
      signals: [
        { signal: "The engineer sends a second round of clarifying questions after the first has been answered.", measurement_method: "Track the number of information-gathering rounds on the cut decision." },
        { signal: "The stalled project remains in 'in progress' status two weeks after the roadmap review.", measurement_method: "Check the project tracker status column." }
      ] },
    { rank: 4, severity: "medium",
      statement: "The session fills its two-hour slot with status updates rather than decisions, and the team runs out of time before addressing the cut project.",
      assumption: "A two-hour meeting with four attendees and 34 backlog items can reach decisions without a structured agenda enforced by a facilitator.",
      signals: [
        { signal: "The first forty-five minutes are consumed by one engineer walking through their work.", measurement_method: "Track time spent on each agenda item; flag if any single item exceeds twenty minutes." },
        { signal: "The cut project is item twelve on the agenda.", measurement_method: "Review the agenda before the meeting; cut decision should be item one or two." }
      ] },
    { rank: 5, severity: "low",
      statement: "The roadmap document that emerges from the session is written at a level of abstraction that means different things to different readers, so apparent alignment dissolves when implementation begins.",
      assumption: "A shared vocabulary for what 'release' and 'cut' mean exists among the four team members.",
      signals: [
        { signal: "Two people describe the same roadmap item with different scope when asked separately.", measurement_method: "After the meeting, ask each team member to describe the top priority in one sentence without looking at the doc. Compare." },
        { signal: "The doc uses phrases like 'approximately', 'as time allows', or 'scope TBD'.", measurement_method: "Review the final doc for hedging language before it is shared outside the team." }
      ] }
  ].each do |fm_data|
    fm = pm.failure_modes.create!(
      rank: fm_data[:rank], severity: fm_data[:severity],
      statement: fm_data[:statement], assumption: fm_data[:assumption]
    )
    fm_data[:signals].each do |ws|
      fm.warning_signals.create!(signal: ws[:signal], measurement_method: ws[:measurement_method])
    end
  end

  [
    { rank: 1, effectiveness_to_effort: 5, description: "Before the session, have the product lead and engineering lead each write down independently what the outcome of this roadmap review will be in one paragraph. Share and compare before the meeting starts." },
    { rank: 2, effectiveness_to_effort: 5, description: "Name the stalled project explicitly at the top of the agenda as a forced choice: cut, complete in two weeks, or hand to an outside contractor. Remove it from discussion until a decision is made." },
    { rank: 3, effectiveness_to_effort: 4, description: "Assign a facilitator (not the product or engineering lead) who is responsible only for keeping time and surfacing disagreement. The new engineer is a reasonable choice." },
    { rank: 4, effectiveness_to_effort: 4, description: "End the session with each team member stating in one sentence what they are personally responsible for shipping in the next six weeks. Write it on the shared doc in front of everyone." },
    { rank: 5, effectiveness_to_effort: 3, description: "Schedule a thirty-minute check-in two weeks after the roadmap session to confirm the cut project has not re-entered the backlog and that work matches the stated priorities." },
    { rank: 6, effectiveness_to_effort: 3, description: "Replace the existing roadmap doc with a simple two-column table: what ships in six weeks, what ships in twelve weeks. No other items. Archive the 34-item backlog separately." },
    { rank: 7, effectiveness_to_effort: 2, description: "Pair the new engineer with the engineering lead for the first two weeks post-roadmap to accelerate context transfer and reduce information-gathering delays on implementation decisions." }
  ].each do |pa|
    pm.preventive_actions.create!(rank: pa[:rank], effectiveness_to_effort: pa[:effectiveness_to_effort], description: pa[:description])
  end

  puts "Seeded: Initiative 1 premortem (#{pm.failure_modes.count} failure modes, #{pm.preventive_actions.count} preventive actions)"
end

# Initiative 2 — no premortem (user runs it live)
Initiative.find_or_create_by!(user: demo_user, name: "Launch the foresight practice writing program") do |i|
  i.time_horizon = "6_months"
  i.success_definition = <<~TEXT.strip
    We have reached 100 paid subscribers at $15/month, publishing one substantive essay per week on applying foresight methods to everyday organizational decisions. The first subscriber cohort has been retained for at least two months.
  TEXT
  i.current_state = <<~TEXT.strip
    Eight essays have been drafted, four of them published as free posts with modest engagement. No paid tier has been launched. The email list has 340 subscribers acquired through the free posts and one mention in a relevant newsletter. Revenue is zero.
  TEXT
  i.team_context = <<~TEXT.strip
    Working solo with a part-time editor who reviews each essay before publication. The editor has never worked on a paid subscription product. The author has run a free newsletter before but has never converted subscribers to paid. The relationship with the editor is new and has not been stress-tested under a deadline.
  TEXT
end

puts "Seeded: Initiative 2 (no premortem — run it live)"
