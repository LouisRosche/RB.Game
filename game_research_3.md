# The execution playbook: a risk-adjusted 18-month plan for solo game development

**Knowing the opportunity and understanding the risks are necessary but insufficient — execution is the only variable that converts research into revenue.** This third and final report synthesizes the strategic blueprint (Report 1) and the empirical reality check (Report 2) into a phase-gated, decision-framework-driven execution plan. Each phase includes concrete deliverables, go/no-go criteria grounded in 2024–2025 benchmark data, budget projections, risk mitigations, and the specific sequence of actions that maximizes survival probability in a market where 62% of published games lose money and 75% of Steam releases receive fewer than 50 reviews. The plan assumes a solo developer with no art skills, minimal budget ($0–150/month discretionary), and 15–25 hours per week of available development time alongside existing employment.

---

## The meta-framework: phase gates, not open loops

The single highest-risk behavior identified across both prior reports is **premature commitment to a single over-scoped project**. Burnout research (Stobo & Moberly, GDC 2024), abandonment data (25–50% of Early Access games never ship), and scope creep patterns all point to the same root cause: developers invest months or years before receiving any market signal. The antidote is **phase-gated development with explicit kill criteria**.

This plan uses four phases, each ending with a **go/no-go decision** informed by quantitative benchmarks. Advancing to the next phase requires meeting minimum thresholds. Failing to meet them triggers a structured pivot — not abandonment of the practice, but redirection of the specific project. This approach mirrors Lean Startup methodology (Ries, 2011) adapted for game development, and aligns with Chris Zukowski's portfolio staircase model where each project builds audience equity regardless of individual commercial outcome.

The four phases:

| Phase | Duration | Objective | Kill Criteria |
|-------|----------|-----------|---------------|
| **0: Foundation** | Weeks 1–6 | Infrastructure, skill baseline, concept validation | N/A (always complete) |
| **1: Roblox MVP** | Weeks 7–20 | Ship minimum viable game, validate retention | D1 retention <15% after 3 iterations |
| **2: Monetization & Growth** | Weeks 21–40 | Achieve sustainable revenue, build community | <$500/month revenue by Week 40 |
| **3: Portfolio Expansion** | Weeks 41–78 | Launch standalone game (Godot/Steam), cross-promote | <2,000 wishlists by Next Fest entry |

Each phase specifies weekly time allocation across the eight roles a solo developer must fill — design, programming, art, sound, marketing, community, business administration, and self-care — with deliberate constraints to prevent context-switching overload. Research on task-switching costs (Monsell, 2003; Rubinstein, Meyer, & Evans, 2001) demonstrates that switching between cognitively distinct tasks can reduce productive capacity by 20–40%. The plan batches similar activities into dedicated blocks to minimize this tax.

---

## Phase 0: Foundation (Weeks 1–6)

**Objective:** Build the non-negotiable infrastructure that every subsequent phase depends on, establish sustainable work habits, and validate a game concept through rapid prototyping — before writing a single line of production code.

### Week 1–2: Business and legal scaffolding

The temptation to skip directly to development is the first trap. Report 2 documented that tax obligations, IP protection, and COPPA compliance create existential risks when addressed retroactively. The following checklist requires approximately 8–12 hours total and eliminates the most common legal vulnerabilities.

**Business formation.** Register a sole proprietorship (free, automatic upon business activity) or single-member LLC ($35–$500 depending on state). For developers in states with low LLC costs (Wyoming: $100, New Mexico: $50), the liability protection justifies immediate formation. Open a dedicated business bank account ($0 at most online banks) and a separate savings account for taxes. Set up automatic transfers of **33% of all game income** to the tax account — this covers the combined 15.3% self-employment tax, federal income tax, and state income tax documented in Report 2.

**Platform accounts.** Create a Roblox developer account (free), enable two-factor authentication (account termination risk from unauthorized access is catastrophic and unrecoverable), and familiarize yourself with the Creator Dashboard. Register a Steam developer account ($100 one-time Steamworks fee — defer this until Phase 3 unless budget allows). Create accounts on itch.io (free) for prototyping distribution.

**IP protection pipeline.** Choose three candidate game names. Search the USPTO TESS database (free) for conflicts. Search Roblox and Steam for existing games with those names. Reserve the domain name for your top choice (~$12/year). **Do not file a trademark yet** — at $350 per class, this investment should wait until Phase 1 validates that the concept has traction. But document your first use in commerce when it occurs, as US trademark law is use-based.

**Financial tracking.** Set up a simple spreadsheet or free accounting tool (Wave, GnuCash) with categories matching deductible expenses: software subscriptions, asset purchases, hardware, home office, marketing, professional development, and game research purchases. Log everything from day one — retroactive categorization is the most commonly failed tax obligation among solo developers.

### Week 2–4: Skill foundation and tool setup

**Roblox Studio proficiency.** Complete the official Roblox "Core Curriculum" tutorial series (free, ~15 hours). Focus specifically on: the Explorer/Properties panel workflow, Server vs. Client script distinction (the most common beginner error per Report 2), basic Luau syntax, and the publishing/testing pipeline. Build and publish a trivial "obby" (obstacle course) — the goal is not quality but **completing the full publish cycle** to demystify the process. Psychological research on self-efficacy (Bandura, 1977) demonstrates that early completion experiences, regardless of scope, build the confidence necessary for sustained effort.

**Adopt Single-Script Architecture immediately.** Per Report 2's Luau architecture section, create a template project using one ServerScript and one LocalScript that `require()` ModuleScripts. This is the architecture used by front-page games (Adopt Me, Brookhaven) and prevents the technical debt that forces rewrites later. Install and configure **ProfileService** (or ProfileStore) for data persistence — never use raw DataStoreService for production.

**Art pipeline establishment.** Install MagicaVoxel (free) and spend 2–3 hours completing beginner tutorials. Create five simple objects (a tree, a building, a vehicle, a character, a UI element) in your chosen art style. The goal is proving to yourself that the art pipeline works, not producing final assets. If budget allows ($10/month), set up Leonardo AI and generate 20 concept art pieces for your game idea — these serve as mood boards and asset references, not final art.

**Sound pipeline establishment.** Download the Sonniss GDC Audio Bundle (200+ GB, free, royalty-free). Bookmark BFXR2 and ChipTone for procedural SFX generation. Install Bosca Ceoil Blue for basic music loops. Spend one hour generating placeholder sounds. Remember: 91% of mobile players play with sound off, so sound enhances but must never be required.

### Week 4–6: Concept validation through rapid prototyping

**Generate three game concepts** in the tycoon/simulator or idle genre (the two highest effort-to-revenue genres identified in Report 1). Each concept should be describable in one sentence and achievable as an MVP in 8–12 weeks. Apply the following filters:

1. **Content treadmill test.** Can the core loop generate variety through systems (procedural generation, modular content, combinatorial mechanics) rather than hand-crafted content? If the game requires constant new content creation to retain players, it will burn out a solo developer. Michael Sellers' framework from Report 2 is the guiding principle: systems over content.
2. **Monetization fit test.** Does the concept naturally support cosmetic and convenience purchases without pay-to-win mechanics? Tycoon/simulators pass this test inherently — decorations, speed-ups, and aesthetic customization are native to the genre.
3. **Social play test.** Does the concept benefit from multiplayer interaction? Roblox's algorithm now weights "Intentional Co-Play Days" heavily, structurally disadvantaging purely single-player experiences. The concept should include at least one cooperative or competitive social mechanic.
4. **Art ceiling test.** Can the game look acceptable with low-poly or voxel art, strong lighting, and post-processing? Report 1 established that a simple scene with great lighting outperforms a detailed scene with flat lighting.
5. **Scope test.** Can an MVP be built in 60–80 hours of development time? If not, the scope is too large for Phase 1.

**Build a paper prototype or Figma mockup** of each concept's core loop. Describe the first 10 minutes of gameplay. Post the three concepts (with mockups) to r/RobloxGameDev, the Roblox DevForum, and your nascent Discord server for feedback. The concept with the strongest community signal advances to Phase 1. If no concept generates enthusiasm, generate three more and repeat — concept validation is cheaper than development.

### Phase 0 deliverables checklist

- [ ] Business entity registered or sole proprietorship documented
- [ ] Dedicated business bank account and tax savings account opened
- [ ] Roblox developer account with 2FA enabled
- [ ] Three candidate game names searched for trademark conflicts
- [ ] Domain name reserved for top candidate
- [ ] Financial tracking system initialized
- [ ] Roblox Core Curriculum completed
- [ ] Trivial game published to Roblox (any quality)
- [ ] Single-Script Architecture template project created with ProfileService
- [ ] Five placeholder art assets created in chosen style
- [ ] Sound pipeline tested with placeholder audio
- [ ] Three game concepts generated, filtered, and validated with community feedback
- [ ] One concept selected for Phase 1 development

**Time investment:** ~60–90 hours over 6 weeks (10–15 hours/week)
**Financial investment:** $0–$62 (domain + optional Leonardo AI month)

---

## Phase 1: Roblox MVP (Weeks 7–20)

**Objective:** Build, ship, and iterate a minimum viable game on Roblox. The success metric is not revenue — it is **retention**. A game that retains players can be monetized; a game that doesn't retain players cannot be saved by better monetization.

### Development sprint structure

Organize the 14-week Phase 1 into three sprints with distinct objectives:

**Sprint 1 (Weeks 7–11): Core loop.** Build only the central gameplay loop — the action players repeat most frequently. For a tycoon game, this is: perform task → earn currency → spend currency → expand capacity. No menus, no tutorials, no cosmetics, no monetization, no sound polish. The core loop must be **fun in isolation**. Playtesting research (Fullerton, 2019) consistently shows that if the core loop isn't engaging without any surrounding systems, adding systems won't fix it.

Publish to Roblox as a **free, unlisted game** and invite 5–10 testers from Discord or DevForum. Measure: do testers play for more than 10 minutes? Do they return the next day? Use Roblox's built-in Creator Analytics to track session length and D1 return rate. If fewer than 3 of 10 testers return on Day 2, the core loop needs fundamental revision before proceeding.

**Sprint 2 (Weeks 11–16): Systems and content.** With a validated core loop, build the surrounding systems: progression curve, UI/UX, tutorial/onboarding, save data (via ProfileService), basic sound, and at least one social mechanic (leaderboard, cooperative task, trading system, or visiting other players' spaces). Apply the accessibility "Big Four" from Report 2: remappable controls, subtitles on by default, separate volume sliders, and no reliance on color alone. Implement internationalization from day one — store all player-facing strings in a ModuleScript lookup table, never hardcode text.

Performance-optimize for low-end devices: keep part count under 75,000, enable StreamingEnabled, set MeshPart RenderFidelity to "Automatic," and anchor all stationary parts. Test on a low-spec machine or Roblox's device emulator.

**Sprint 3 (Weeks 16–20): Polish, soft launch, iterate.** Add visual polish (lighting, particle effects, post-processing), sound design, a game icon and thumbnails optimized for the Roblox discovery page, and a compelling game description with relevant keywords. Publish publicly as a **free game with no monetization**. The absence of monetization is deliberate — it removes a variable and isolates retention as the only metric that matters at this stage.

### Retention benchmarks and the go/no-go decision

After one week of public availability with at least 100 unique players (use social media, DevForum, and Discord to drive initial traffic), evaluate against these benchmarks derived from the GameAnalytics data in Report 2, adjusted for Roblox's context:

| Metric | Minimum (Go) | Target | Excellent |
|--------|-------------|--------|-----------|
| D1 Retention | 20% | 30% | 40%+ |
| D7 Retention | 5% | 10% | 15%+ |
| Average Session Length | 8 min | 15 min | 25+ min |
| Sessions per User (Week 1) | 1.5 | 2.5 | 4+ |

**Go criteria:** D1 retention ≥20% after at least two iteration cycles based on player feedback. If D1 stays below 15% after three significant iterations (each requiring at least one week of data), trigger the **pivot protocol**: shelve the current concept, return to Phase 0 concept validation, and begin a new MVP. This is not failure — it is the portfolio staircase model in action. Chris Zukowski's data shows second games sell 40% better than first games regardless of the first game's commercial outcome.

**Iterate relentlessly during this sprint.** Read every piece of player feedback. Watch session recordings if possible (Roblox doesn't offer this natively, but you can observe testers via screen share). The most common fixable retention killers for Roblox games are: confusing onboarding (players leave within 60 seconds because they don't understand what to do), insufficient early reward frequency (the dopamine feedback loop is too slow in early gameplay), and performance issues on mobile devices (Roblox's mobile user base is substantial and plays on low-end hardware).

### Community building begins now

**Discord server.** Create a server with channels for: announcements, feedback/suggestions, bug reports, general chat, and a screenshots/clips channel. Add a welcome message explaining the game's vision and inviting honest feedback. The target is **50 engaged members by Week 20** — not 50 joiners, but 50 people who have posted at least once. Research on community-driven conversion (Report 2) shows that 500+ engaged Discord members correlates with 25–40% higher conversion rates at launch.

**Social media cadence.** Post development updates twice per week on TikTok (short gameplay clips with hooks in the first second), once per week on the Roblox DevForum (devlogs with technical detail that invite community feedback), and as appropriate on genre-relevant subreddits (following the 10:1 contribution-to-promotion ratio). Do not create a Twitter/X account solely for the game — the platform's organic reach for small creators has declined dramatically, and the time is better spent on TikTok and Reddit where discoverability algorithms still favor new creators.

### Phase 1 deliverables checklist

- [ ] Core gameplay loop built and validated with testers
- [ ] Full MVP published on Roblox with tutorial, UI, save system, and social mechanic
- [ ] Accessibility Big Four implemented
- [ ] Internationalization infrastructure in place (string tables, UTF-8)
- [ ] Performance optimized for low-end devices (<75K parts, StreamingEnabled)
- [ ] D1 retention ≥20% confirmed with 100+ unique players
- [ ] Discord server at 50+ engaged members
- [ ] Consistent social media posting cadence established
- [ ] All player feedback documented and categorized

**Time investment:** ~150–200 hours over 14 weeks (11–14 hours/week)
**Financial investment:** $0–$40/month (optional AI art tools)

---

## Phase 2: Monetization and Growth (Weeks 21–40)

**Objective:** Layer ethical monetization onto the validated, retaining game and grow the player base to sustainable revenue. The guiding framework is Self-Determination Theory (Ryan & Deci): every purchase should support **autonomy** (genuine player choice), **competence** (mastery expression), or **relatedness** (social identity expression).

### Monetization implementation sequence

Introduce monetization **incrementally**, measuring the impact of each addition on retention before adding the next. A sudden shift from free to heavily monetized will alienate the early community that provided feedback and built word-of-mouth.

**Week 21–24: Cosmetic shop (first monetization layer).** Add 10–15 cosmetic items (skins, decorations, visual effects) priced between 50–500 Robux ($0.63–$6.25 at current exchange). Use Roblox's built-in **price optimization tool** to A/B test pricing on each item. Cosmetics should signal creativity and personality, not spending power — avoid any items that create visible spending hierarchies. Monitor D1 and D7 retention after cosmetic shop launch: if retention drops more than 3 percentage points, the shop is perceived as intrusive and needs UX revision.

**Week 25–28: Game passes (second monetization layer).** Add 2–3 game passes for convenience features: a permanent 2× speed multiplier ($4.99 equivalent), an auto-collect pass ($2.99), and a VIP server cosmetic pack ($9.99). These are one-time purchases that feel fair because they save time without creating competitive advantage. Report 1's analysis of top Roblox earners (Blox Fruits, Grow a Garden) confirms that convenience passes are the most reliable solo-developer revenue stream.

**Week 29–32: Seasonal content and battle pass (third monetization layer, optional).** If retention and revenue justify the ongoing content investment, introduce a 4–6 week seasonal event with a dual-track free/premium pass. The premium pass should cost 400–600 Robux (~$5–7.50) and return enough premium currency to fund 60–75% of the next pass (reducing FOMO while maintaining revenue). Use the seasonal rotation strategy from Report 2: re-skin existing mechanics with themed content rather than building entirely new systems. Ten base assets × 4 seasonal themes = 40 cosmetic items from minimal incremental effort.

### Revenue benchmarks and the go/no-go decision

Track revenue weekly. The following benchmarks assume a game with 500–2,000 daily active users, which is achievable for a retaining Roblox game with active community management:

| Metric | Minimum (Go) | Target | Excellent |
|--------|-------------|--------|-----------|
| Monthly Revenue (Robux) | 130K (~$500 USD) | 520K (~$2,000 USD) | 1.3M+ (~$5,000+ USD) |
| Conversion Rate | 1.5% | 3% | 5%+ |
| ARPDAU | $0.03 | $0.08 | $0.15+ |
| DAU | 500 | 1,500 | 5,000+ |

**Go criteria for Phase 3:** Monthly revenue ≥$500 USD sustained for 8+ weeks, AND Discord community ≥200 engaged members, AND D7 retention ≥8%. Meeting all three indicates a validated, retaining, monetizing game with an engaged community — the prerequisites for portfolio expansion.

**If revenue stays below $500/month by Week 40** despite strong retention (D1 ≥25%), the issue is likely discovery, not product quality. Before pivoting, attempt: (1) a targeted TikTok campaign with 5–10 short clips emphasizing the game's most visually striking moments, (2) reaching out to 3–5 small Roblox YouTubers/TikTokers for coverage, and (3) optimizing the game's title, icon, and description for Roblox search. If revenue remains below threshold after 4 additional weeks, begin Phase 3 concept development in parallel rather than continuing to pour resources into a game that has hit its ceiling.

### Growth strategies ranked by effort-to-impact for solo developers

**Algorithm optimization (highest ROI, lowest effort).** Roblox's discovery algorithm uses six per-user signals. The two most actionable are session time (longer sessions signal quality) and Intentional Co-Play Days (players who invite friends). Add explicit friend-invite mechanics: cooperative tasks that require two players, shared rewards for playing together, and easy-access private server creation. Every co-play session improves your algorithmic position.

**Micro-influencer outreach (high ROI, moderate effort).** Identify 20 Roblox content creators with 5,000–50,000 subscribers. These creators are far more responsive than large influencers and their audiences convert at higher rates. Offer early access, exclusive in-game items named after them, and — only if budget allows — small payments ($25–$100 per video). One creator with 20,000 subscribers can drive 500–2,000 new players.

**Cross-promotion within Roblox (moderate ROI, moderate effort).** Partner with 2–3 non-competing Roblox developers at similar audience sizes for mutual promotion: in-game portals, shared events, or Discord cross-posting. This costs nothing and exposes each game to a pre-qualified audience (people who already play Roblox).

**Content marketing (moderate ROI, high effort).** Devlogs on TikTok and YouTube Shorts showing behind-the-scenes development resonate strongly with the Roblox creator community. A weekly 60-second clip showing "what I added this week" builds narrative investment in your game's success. Developer "M" of *I Just Want to be Single!!* earned 2,900 wishlists from a single TikTok — the asymmetric upside justifies the time investment.

### Phase 2 deliverables checklist

- [ ] Cosmetic shop launched with 10–15 items, prices A/B tested
- [ ] 2–3 convenience game passes launched
- [ ] Retention monitored post-monetization (no significant degradation)
- [ ] Optional: seasonal event with dual-track pass
- [ ] Revenue ≥$500/month sustained for 8+ weeks
- [ ] Discord community ≥200 engaged members
- [ ] At least one micro-influencer collaboration completed
- [ ] Algorithm optimization features (co-play mechanics) implemented
- [ ] Localization into Simplified Chinese and Portuguese (if community data supports it)

**Time investment:** ~200–250 hours over 20 weeks (10–12 hours/week)
**Financial investment:** $0–$50/month tools + optional influencer budget

---

## Phase 3: Portfolio Expansion (Weeks 41–78)

**Objective:** Leverage the Roblox audience, community, and revenue stream to launch a standalone game on Steam via Godot, establishing full IP ownership and platform independence. This phase executes the dual-platform strategy from Report 1 while mitigating the Roblox platform risks documented in Report 2.

### Why Godot, and why now

The decision to use Godot 4 for the standalone game is grounded in five factors validated across both prior reports:

1. **Zero royalties at any revenue level** (MIT license). Unity charges subscription fees; Unreal takes 5% after $1M. Godot takes nothing, ever.
2. **Full IP portability.** Unlike Roblox, where games cannot be exported, Godot projects can be published to Steam, Epic Games Store, itch.io, mobile stores, and (with third-party tools) consoles.
3. **Community momentum.** Godot surpassed Unreal Engine in usage at the 2024 Global Game Jam. The ecosystem of tutorials, plugins, and community support has reached critical mass.
4. **Transferable skills.** GDScript shares conceptual DNA with Python and Lua/Luau. A developer proficient in Roblox Luau can become productive in Godot within 2–4 weeks.
5. **2D excellence.** For solo developers, 2D games have dramatically lower art requirements than 3D. Godot's 2D engine is considered best-in-class among free alternatives.

### Development approach: parallel tracks

**Track A: Roblox maintenance (4–6 hours/week).** The Roblox game continues generating revenue and community engagement. Shift to a maintenance cadence: one content update every 5–6 weeks (the minimum Report 1 identified for sustaining tycoon/simulator engagement), community management, and bug fixes. This is the financial foundation that funds Phase 3 development and reduces the financial pressure that drives burnout.

**Track B: Godot standalone development (8–12 hours/week).** Begin with the official Godot "Your First 2D Game" tutorial (~4 hours), then immediately start building. The standalone game should be in the same genre family as your Roblox game but **not a direct port** — Roblox's always-online multiplayer design patterns don't translate well to offline-capable standalone games. Instead, create a game in the same thematic universe that appeals to the same player motivations (per Nick Yee's Gamer Motivation Model), enabling cross-promotion between the two titles.

### Steam launch preparation

The Steam launch pipeline requires specific milestones documented extensively in Report 2's discovery section. The following timeline integrates those requirements:

**Weeks 41–55: Development and store page.** Build the game to a state sufficient for a compelling Steam store page: at least 5 screenshots, a 30–60 second trailer (even if rough), a description emphasizing the game's unique selling proposition, and system requirements. Pay the $100 Steamworks fee and publish the store page. Begin collecting wishlists immediately — the Steam algorithm begins tracking interest from the moment the page goes live.

**Weeks 55–65: Wishlist building.** Target minimum **7,000 wishlists** before launch (the bare minimum for a modest launch per Report 2). The primary channels, ranked by conversion efficiency: TikTok gameplay clips (1,000–2,000 wishlists per viral video), Reddit posts in genre-relevant subreddits (following the 10:1 ratio), cross-promotion from your Roblox game and Discord community, and Steam Next Fest participation.

**Weeks 65–70: Steam Next Fest demo.** Build a polished 15–30 minute demo for Steam Next Fest. Average entrants double their wishlist base, gaining 1,000–3,500 wishlists. Enter with at least 2,000 existing wishlists for meaningful algorithmic lift. The demo must represent your best work — Next Fest is "probably the single most important pre-launch campaign beat for an indie title."

**Weeks 70–78: Launch.** Implement pre-launch localization into the top 3 non-English Steam languages: Simplified Chinese, German, and Brazilian Portuguese. Each adds approximately 30% revenue potential. Use the hybrid localization approach from Report 2 (community translation + professional editor) at ~$450 for three languages versus $2,100 through an agency.

Price the game at $9.99–$14.99. Report 1's data on premium purchase models (Stardew Valley, Balatro, Schedule 1) shows that the premium-with-free-updates model generates extraordinary goodwill and long-tail sales. If the game concept supports it, consider launching on the **Epic Games Store simultaneously** — their 100% revenue share on the first $1M annually (effective June 2025) makes dual-listing highly attractive.

**File the trademark** before public announcement. Class 9 (software) and Class 41 (entertainment services) at minimum ($700 total DIY). Report 1 documented that unauthorized merchandise appears immediately after a game gains traction — trademarks make enforcement dramatically easier.

### Phase 3 go/no-go: the portfolio decision

At the end of Phase 3, evaluate the combined portfolio:

| Outcome | Roblox Game | Steam Game | Decision |
|---------|------------|------------|----------|
| Both succeeding | >$1K/month | >5,000 copies in Month 1 | Continue both; evaluate hiring first contractor |
| Roblox succeeding, Steam underperforming | >$1K/month | <1,000 copies in Month 1 | Maintain Roblox revenue; iterate on Steam marketing; begin Game 3 concept |
| Steam succeeding, Roblox declining | <$500/month | >5,000 copies | Shift focus to Steam ecosystem; Roblox on minimal maintenance |
| Both underperforming | <$500/month | <1,000 copies | Full portfolio assessment; reapply Phase 0 concept validation with accumulated skills |

Even the "both underperforming" scenario leaves you with two shipped games, a community, transferable skills across two engines, and the statistical advantage that second and third games sell 40% and 64% better respectively than first attempts. The portfolio staircase is working even when individual stairs feel flat.

---

## Cross-cutting systems: what runs throughout all phases

### Time management architecture

The research on solo developer burnout (Report 2, Section 9) identifies context switching across 8–10 roles as a primary driver. The mitigation is **role batching**: dedicate specific days or blocks to specific roles rather than switching throughout every session.

**Recommended weekly schedule (15–20 hours/week alongside full-time employment):**

| Day | Block | Activity | Duration |
|-----|-------|----------|----------|
| Monday | Evening | Development (coding, building) | 2.5 hrs |
| Tuesday | Evening | Development (coding, building) | 2.5 hrs |
| Wednesday | Evening | Art/sound asset creation | 2 hrs |
| Thursday | Evening | Community management, feedback review | 1.5 hrs |
| Friday | Evening | Marketing content creation (TikTok, devlog) | 1.5 hrs |
| Saturday | Morning | Development (coding, building) | 3–4 hrs |
| Saturday | Afternoon | Playtesting, bug fixes, analytics review | 2 hrs |
| Sunday | — | **No development. Mandatory rest.** | 0 hrs |

The Sunday prohibition is non-negotiable. Research on creative recovery (Sonnentag & Fritz, 2007) demonstrates that psychological detachment from work during off-time is the strongest predictor of reduced exhaustion and sustained performance. Eric Barone's 70-hour weeks produced Stardew Valley but also produced severe burnout — the plan must be sustainable for 18 months, not optimized for a 3-month sprint.

**Use the Pomodoro Technique** (25 minutes focused work, 5-minute breaks, longer break every 4 cycles) for all development sessions. Set a hard stop time for each evening session and enforce it with an alarm. The research is clear: working past the point of diminishing returns doesn't produce more output — it produces more bugs, worse design decisions, and accelerated burnout.

### Financial model and projections

The following projection uses conservative assumptions grounded in Report 2's median benchmarks, not Report 1's aspirational case studies. The purpose is to establish realistic expectations and identify the break-even point.

**Expense budget (monthly):**

| Category | Phase 0–1 | Phase 2–3 | Notes |
|----------|-----------|-----------|-------|
| AI art tools | $10–30 | $10–30 | Leonardo AI, Meshy (optional) |
| Domain name | $1 | $1 | Annual cost amortized |
| Sound tools | $0 | $0 | Free tools sufficient |
| Steam developer fee | $0 | $8.33 amortized | $100 one-time in Phase 3 |
| Trademark | $0 | $58.33 amortized | $700 filed in Phase 3 |
| Marketing | $0 | $0–100 | Micro-influencer outreach (optional) |
| **Total** | **$11–31** | **$77–197** | |

**Revenue projection (conservative, 25th–50th percentile outcomes):**

| Phase | Month | Projected Monthly Revenue | Cumulative |
|-------|-------|--------------------------|------------|
| Phase 1 | Months 2–5 | $0 | $0 |
| Phase 2 | Months 6–8 | $100–300 | $300–900 |
| Phase 2 | Months 9–10 | $300–800 | $900–2,500 |
| Phase 3 | Months 11–14 | $500–1,500 (Roblox) | $2,900–8,500 |
| Phase 3 | Months 15–18 | $500–1,500 (Roblox) + Steam launch | $5,000–20,000+ |

**Break-even on direct costs** (tools, fees, trademark): approximately **Month 8–10** at the conservative projection. Break-even on **opportunity cost** (valuing your time at any wage) takes significantly longer and may never occur for the first game — which is precisely why the plan treats the first game as portfolio foundation, not standalone bet.

### Mental health and sustainability protocols

Report 2 documented that 53% of developers experience crunch or extended hours, and that burnout is the default outcome for solo developers. The following protocols are grounded in occupational health research and game-industry-specific resources.

**Scope management.** Maintain a single document listing every feature in the current game, categorized as: shipped, in-progress (maximum 2 at any time), planned (maximum 5), and rejected. When adding a feature to "planned," remove one. This artificial constraint prevents the scope creep that Report 2 identified as the single most common burnout precursor. Apply the "no, unless" rule: the default answer to "should I add this feature?" is no, unless it directly improves the core retention metric.

**Progress visibility.** Human motivation research (Amabile & Kramer, 2011) identifies the "progress principle" — small wins are the single most powerful driver of sustained motivation. Maintain a changelog that documents every improvement, no matter how small. Review it weekly. On difficult weeks, the changelog provides objective evidence of forward movement that counters the subjective feeling of stagnation.

**Social connection.** Join at least one developer community with active voice or video interaction (not just text chat). Options include: the Roblox DevForum, genre-specific Discord servers, local IGDA chapter meetups, game jam teams, or the Limit Break Mentorship program. Report 2's burnout research identified isolation as the second-strongest burnout predictor after scope. Weekly social contact with other developers is protective.

**Crisis resources.** Bookmark Take This (takethis.org) and Safe In Our World (safeinourworld.org) for game-industry-specific mental health support. If financial stress from development costs becomes a mental health concern, pause monetization experiments and return to the lowest-cost maintenance mode. No game is worth a mental health crisis.

### Risk registry and mitigation

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Roblox account termination | Low | Catastrophic | Enable 2FA; comply strictly with ToS; never use Free Models without inspection; maintain local backups of all scripts and asset source files |
| Roblox ToS/revenue share change | Medium | High | Dual-platform strategy (Phase 3); never rely on Roblox as sole income; maintain Godot skills |
| Algorithm change kills discovery | Medium | High | Diversify traffic sources (Discord, TikTok, Reddit); build direct community relationships independent of platform |
| Burnout/abandonment | High | Catastrophic | Mandatory rest days; strict scope limits; social connection protocols; phase-gate structure allows clean exit points |
| Negative review spiral | Medium | Medium | Do not read reviews during development hours (batch review reading into community management block); prepare emotionally for mixed reception |
| Tax/legal surprise | Low | Medium | 33% automatic tax set-aside; quarterly estimated payments; keep all receipts from day one |
| Copyright claim on AI-generated assets | Low | Medium | Use tools with clear commercial licenses (Leonardo AI paid plan, Meshy paid plan); maintain documentation of generation process; supplement with CC0 assets from Kenney.nl |
| Game concept fails validation | High | Low | Phase-gate structure means <90 hours invested before kill decision; portfolio model means each attempt builds skills for the next |

---

## The 18-month decision tree

The entire plan can be summarized as a single decision tree that a developer can reference at any point to understand where they are and what to do next.

```
START
│
├─ Phase 0 (Weeks 1–6): Build infrastructure, validate concept
│   └─ Concept validated? 
│       ├─ YES → Phase 1
│       └─ NO → Generate new concepts, repeat validation
│
├─ Phase 1 (Weeks 7–20): Build and ship Roblox MVP
│   └─ D1 retention ≥20% after 3 iterations?
│       ├─ YES → Phase 2
│       └─ NO → Shelve concept, return to Phase 0 with new concept
│           └─ (Skills and community carry forward)
│
├─ Phase 2 (Weeks 21–40): Monetize and grow
│   └─ Revenue ≥$500/month sustained + 200 Discord members + D7 ≥8%?
│       ├─ YES → Phase 3
│       └─ NO (but retention strong) → Optimize discovery, extend 4 weeks
│       └─ NO (retention weak) → Begin new concept in parallel
│
├─ Phase 3 (Weeks 41–78): Launch standalone on Steam via Godot
│   └─ Portfolio assessment at Month 18
│       ├─ Both games generating revenue → Scale (hire contractor, expand)
│       ├─ One game succeeding → Double down on winner
│       └─ Neither succeeding → Reapply framework with Game 3
│           └─ (2 shipped games + community + skills = dramatically better odds)
│
END STATE: Sustainable portfolio with platform diversification,
           IP ownership, and community equity
```

---

## Conclusion: the only metric that matters is shipping

Report 1 documented the opportunity: AI tools eliminating the art barrier, Roblox's improved economics, and ethical monetization outperforming exploitative alternatives. Report 2 documented the risks: 62% of games losing money, platform dependence, content treadmills, burnout, and brutal power law distributions. This report provides the execution bridge between knowing and doing.

The research converges on a single, uncomfortable truth: **the primary differentiator between successful and unsuccessful solo developers is not talent, tools, or luck — it is the number of completed projects shipped.** Second games sell 40% better. Third games sell 64% better. Published games sell 6× more than self-published ones. Every shipped project, regardless of commercial outcome, builds the skills, audience, and pattern recognition that compound into eventual viability.

The phase-gate structure exists to make shipping psychologically manageable. By committing to a 60–80 hour MVP rather than a multi-year magnum opus, the plan ensures that the first complete cycle happens within months, not years. By establishing quantitative kill criteria, it prevents the sunk-cost fallacy that keeps developers pouring time into projects that the market has already rejected. By mandating rest days and social connection, it protects the developer's most irreplaceable resource — themselves.

The median outcome of this plan is not a six-figure game business. The median outcome is a developer who ships two games in 18 months, earns $5,000–$20,000, builds a community of several hundred engaged players, masters two game engines, and has dramatically improved odds on their third and fourth attempts. That is not a failure state. That is the foundation every major indie success story was built on — from Scott Cawthon's dozens of forgotten Christian games before FNAF, to Eric Barone's years of invisible effort before Stardew Valley, to Innersloth's two years of 5–25 concurrent players before Among Us became the most-played game on Earth.

Start Phase 0 this week. The infrastructure takes 12 hours. The concept validation takes 20. The first published game takes 150. The compound returns start from the moment you ship.
