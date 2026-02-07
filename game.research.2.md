# The reality check: what solo game development actually looks like

**The overwhelming majority of solo game developers earn less than minimum wage, and most games never find an audience.** The median indie game on Steam earns roughly $1,200 in its entire lifetime — about 8% of US federal minimum wage — while the median Roblox DevEx payout sits at $1,575 per year. Only **2.4%** of the 18,324 games released on Steam in 2024 crossed the 1,000-review threshold considered "successful," and 62% of developers report their last published game lost money. This report systematically addresses 12 dimensions overlooked or underweighted in prior optimistic analysis, grounding each in 2024–2025 empirical data. The goal is not to discourage, but to equip solo developers with the sober realities needed to make informed decisions, manage risk, and build sustainable practices.

---

## 1. Most games fail, and the math proves it

The indie game market follows a brutal power law distribution, not a bell curve. **The top 10% of indie games capture 89% of all indie revenue on Steam**, leaving the remaining 90% to split just 11%. In 2024, Steam saw a record 18,324 new releases — a 30.8% year-over-year increase — yet nearly half (49.8%) received fewer than 10 reviews, suggesting fewer than 300 copies sold. Fully **75%** received fewer than 50 reviews. Only about 445 indie/AA games cleared the 1,000-review mark that analyst Chris Zukowski considers the floor for "success."

The revenue concentration is staggering. **80% of indie games earn less than $5,000 in their entire lifetime.** A game that grosses $10,000 — barely enough to cover a few months of expenses — already sits in the 68th percentile, beating two-thirds of all competitors. Yet Steam's algorithm doesn't begin actively promoting games until they reach approximately $250,000 in revenue, the 91.5th percentile. This creates a brutal dead zone: games that are "above average" but invisible.

On Roblox, the concentration is even more extreme. Approximately **40 million games** exist on the platform, but only about 160 had more than 1 billion visits in the past 12 months. Of the millions of creators attempting to monetize, only **24,500** qualify for Roblox's DevEx program (which converts Robux to real money). The top 10 developers averaged $33.9 million each in 2024, while the median DevEx participant received **$1,575 for the entire year**. The vast majority of Roblox creators earn precisely zero dollars.

Jake Birkett's developer survey found that **62% of developers' most recent published games lost money** (including the developer's imputed salary). Only 38% broke even or profited — and Birkett noted this was "WAY higher than I was expecting." The GDC 2025 State of the Game Industry survey of 3,000+ developers revealed that 56% self-fund their games, 22% hold second jobs, and 13% work 51+ hours per week, up from 8% previously.

**Abandonment is the norm, not the exception.** Only about 25–50% of Steam Early Access games ever reach full release. Game jam projects — often cited as launchpads — overwhelmingly stay as prototypes. The typical solo developer experience involves seeing "so little progress from week-to-week, month-to-month," with successful solo projects typically requiring 2–3 years of sustained effort and Early Access stretching median development time to 4.5 years.

Survivorship bias profoundly distorts public perception. Media coverage of games like Stardew Valley, Undertale, and Balatro creates the impression that indie success is accessible, while the thousands of failed projects receive almost no coverage. Chris Zukowski's "visibility fulcrum" illustrates this perfectly: the algorithm doesn't promote you until you're already winning, and the media doesn't cover you until the algorithm promotes you.

---

## 2. Roblox's platform risk is structural, not hypothetical

Building on Roblox means accepting a uniquely lopsided economic relationship. **Developers receive approximately 19–29% of actual user spending** on free-to-play games after Roblox's cuts, DevEx exchange rates, and app store fees. Compare this to Steam (70%), Epic Games Store (88%), or Apple/Google's small developer programs (85%). A 2019 open letter signed by 60+ top Roblox developers — including creators of Adopt Me, Bee Swarm Simulator, and Welcome to Bloxburg — explicitly stated that the revenue share "prevents Roblox development from being sustainable." Seven years later, the fundamental economics have barely improved.

**Roblox has never posted a profitable quarter as a public company.** The company reported net losses of $940.6 million in 2024 and $1.07 billion in 2025, despite $4.8 billion in revenue. The SEC and FTC both opened investigations following a Hindenburg Research report in October 2024 that accused Roblox of inflating daily active user metrics by 25–42%. Multiple child safety lawsuits are pending. This financial and regulatory precariousness creates real risk: a company losing over a billion dollars annually may eventually need to cut developer payouts further.

The platform's Terms of Service changed four times in 2024 alone. The January 2024 update made developers **responsible for player behavior** in their games — if users post violating content, the developer's game can be deleted. In July 2025, "Premium Payouts" were replaced with "Creator Rewards," and multiple developers reported losing income overnight, with one going from 76,000 Robux per week to zero. Developers have no negotiating power and no advance notice of policy changes that can destroy their economics.

**Account termination represents catastrophic, unrecoverable risk.** If a developer's account is banned, all games, assets, Robux, and years of work are permanently lost. Roblox's code and assets use the proprietary Luau language and Roblox-specific APIs — nothing can be exported to another engine. The DevForum documents numerous cases of false bans from automated moderation, including a developer banned with $25,000 in confiscated Robux and a 10-year veteran who lost income-generating games. The appeal system relies heavily on AI-generated responses, and many developers report receiving no meaningful human review.

Discovery on Roblox is algorithm-dependent and binary. Over **90% of traffic originates from the algorithm-driven Home page**, and developers describe the experience as either being "on the algorithm or off the algorithm, with no in-between." The December 2025 algorithm update introduced "Intentional Co-Play Days" as a key signal, explicitly favoring games where players invite friends — structurally disadvantaging solo-developed single-player experiences. Among 40 million games, getting algorithmic lift is like winning a lottery.

The demographic challenge compounds these issues. Approximately **40% of Roblox players are under 13**, with limited spending power. Roblox's global ARPU of ~$11.96 is far below adult-oriented platforms. CEO Baszucki has acknowledged the 18+ cohort "monetizes 40% higher," but reaching that cohort requires competing against platforms purpose-built for adults. New COPPA-driven restrictions — social hangout games restricted to 13+, default DM blocking for under-13s — are shrinking the addressable audience for many game types retroactively.

---

## 3. Retention benchmarks are declining, and the content treadmill is real

Industry retention rates **dropped significantly from 2023 to 2024**, reflecting intensifying competition. Based on GameAnalytics data from 10,000+ projects serving 2.7 billion monthly active users, median Day 1 retention across all mobile games fell to **22.91%** (down from 28–29% in 2023). Median Day 7 dropped to 3.42–3.94%, and Day 28 landed at just 0.85%. Even top-quartile games achieve only D1: 27%, D7: 8%, D28: 3%.

Aspirational "good" targets cited by the industry — D1: 40%+, D7: 20%+, D30: 10%+ — represent the **90th percentile** of all games. For a realistic solo developer, targeting D1: 25–35%, D7: 8–15%, and D30: 3–6% places you in a competitive but achievable range. Genre matters enormously: match-3 games regularly exceed 50% D1, while arcade games have high D1 but terrible long-term retention.

The most effective ethical retention mechanics align with Self-Determination Theory's three pillars: **autonomy** (meaningful player choices), **competence** (mastery and skill progression), and **relatedness** (social connection). Research from ECCE 2024 found that 85% of players stopped playing a game due to dissatisfaction with the monetization model, making ethical design not just moral but commercially advantageous. Cosmetic-only monetization, skill-based progression, social systems, and flow-state design outperform dark patterns long-term.

The **"content treadmill"** — where developers create hand-crafted content that players consume faster than it can be produced — is perhaps the most dangerous trap for solo developers. Game design theorist Michael Sellers identified this cycle as fundamentally unsustainable: "The game is fundamentally content-limited because it is so directly authored by the designers." The solution is **systems over content**. Procedural generation (Perlin noise terrain, Wave Function Collapse for levels, randomized loot modifiers), modular content architecture (10 weapon bases × 10 modifiers × 5 visuals = 500 unique items from 25 assets), and player-generated content all help solo developers escape the treadmill. Seasonal content rotation — re-skinning existing events for different themes rather than creating everything from scratch — is the minimum viable LiveOps approach.

For analytics, solo developers should start with **GameAnalytics** (free up to 2 million MAU) for cross-platform games, or Roblox's built-in Creator Analytics Dashboard. The critical F2P KPIs are DAU/MAU ratio (10–20% average, 20%+ excellent), conversion rate (1–5% typical, with 2% median), and ARPDAU ($0.05–$0.20 for casual games). Roblox now offers a built-in **price optimization tool** that A/B tests game pass pricing automatically — one of the few genuine advantages of the platform.

---

## 4. Discovery requires strategy, not just quality

Quality is necessary but insufficient. The graveyard of indie games is filled with well-made titles nobody played. For solo developers with zero marketing budget, the research points to a clear priority hierarchy.

**TikTok has become the most powerful free discovery channel for indie games.** A single viral video can drive 1,000–2,000 Steam wishlists, compared to 50–70 from even viral tweets. Developer "M" of the visual novel *I Just Want to be Single!!* earned 2,900 wishlists from one TikTok video (571K views), doubling their total wishlist count in a month. The platform rewards completion rate and loops, meaning short, visually striking clips with hooks in the first second perform best. The critical caveat is conversion friction — TikTok users are on mobile, while Steam is on PC, so many viewers search the game name on Steam later rather than clicking links directly.

**Steam wishlists are the currency of indie game launches.** Median wishlist-to-Week 1 sales conversion sits at **0.17x** (for games with 10,000+ wishlists), meaning 10,000 wishlists yield roughly 1,700 first-week sales. Publishers typically target 30,000+ wishlists before launch, while 7,000 represents the bare minimum for a modest launch. **Steam Next Fest** is described as "probably the single most important pre-launch campaign beat for an indie title" — average entrants double their wishlist base during the week, gaining 1,000–3,500 wishlists. However, entering with fewer than 2,000 existing wishlists yields minimal algorithmic lift.

Reddit reaches a unique audience — **74% of gaming Redditors aren't on Discord, and 64% aren't on Twitch** — making it a distinct discovery channel. Solo developer Matias Colotto generated over $400,000 in 12 months from *Magic Research* with only two Reddit posts on r/incremental_games. The key is finding your niche subreddit, following the 10:1 ratio (nine community contributions per self-promotional post), and leading with gameplay footage rather than sales pitches.

For Roblox specifically, the discovery algorithm now uses six per-user signals, with **Intentional Co-Play Days** as the most significant new metric. Games that facilitate friend invites, cooperative play, and private servers receive algorithmic preference. Importantly, signals are calculated as per-user averages, meaning small games with engaged players are not inherently disadvantaged against large ones — but the emphasis on social play means games must be designed for it from the start.

Game jams remain a proven launchpad: Celeste, Superhot, Hollow Knight, Surgeon Simulator, Baba Is You, and Goat Simulator all originated as jam entries. Over 40% of jam projects continue development beyond the event. The compressed feedback loop — knowing within 48–72 hours whether a concept resonates — makes jams an efficient validation tool.

---

## 5. Sound design is critically undervalued by solo developers

Sound is the most consistently overlooked dimension of indie game development, yet research demonstrates its outsized impact. Games with strong musical themes see approximately a **30% increase in player retention rates**, and a study of the game *DOOM* found male gamers scored nearly twice as many points with sound on versus off. However, there's an important counterpoint for mobile: over **91% of mobile game players play with sound off**, particularly in casual/puzzle genres. This means sound should enhance the experience without being essential for gameplay.

The free tool ecosystem for non-musicians is remarkably capable. For sound effects, **BFXR2** (browser-based, Apache 2.0 license) and **ChipTone** generate retro-style SFX with full commercial rights. **Sonniss GDC Audio Bundles** provide over 200GB of professional, royalty-free game audio accumulated from 2016–2024 — an extraordinary free resource. For music, **Bosca Ceoil Blue** lets complete beginners create looping game music in minutes, while **LMMS** offers a full-featured free DAW for more ambitious compositions.

AI music generation tools present legal minefields. **Suno** offers commercial licenses on paid plans ($10+/month), but explicitly states it makes "no representation or warranty" that copyright will vest in any output. All three major labels sued both Suno and Udio for copyright infringement in June 2024. **Udio** is pivoting to a walled-garden model where creations cannot leave the platform, making it unsuitable for game music. The safest AI option is **AIVA**, which offers full copyright ownership on paid plans and focuses on instrumental/cinematic music. For implementation, both **FMOD** (free under $200K revenue) and **Wwise** (free under 200 assets) provide professional audio middleware accessible to non-programmers.

---

## 6. Accessibility expands your market by 20% or more

An estimated **20–30% of all gamers have a disability** — roughly 46 million people in the United States alone. The Accessibility Foundation found that 92% of disabled people play video games, and disabled gamers play more frequently, for longer sessions, and are more likely to make in-game purchases than average. Yet **6.2 million individuals report they cannot play games** because of their disability. This represents both a moral imperative and a significant market opportunity.

The most impactful accessibility features are also the easiest to implement. **Remappable controls** (most engines have built-in support), **subtitle options** with size sliders (defaulting to ON), **separate volume sliders** for music/SFX/speech, and **not relying on color alone** for essential information constitute the "Big Four" most commonly requested features. When Ubisoft turned subtitles on by default in Assassin's Creed Odyssey, **95% of players left them on**, versus 60% who manually enabled them in Origins. Uncharted 4's one-handed control option was used by one-third of all players. These aren't niche accommodations — they're features the mainstream audience wants.

The Xbox Accessibility Guidelines and gameaccessibilityguidelines.com provide free, structured checklists. The latter organizes recommendations into Basic (~30 guidelines), Intermediate (~30), and Advanced (~30) tiers, with the Basic tier achievable by any solo developer. A difficulty/assist mode modeled on Celeste's approach — adjustable game speed, invincibility toggle, extra stamina, framed without patronizing language — is one of the highest-impact features relative to implementation effort.

---

## 7. Localization ROI is measurable and often overlooked

Over **50% of global gaming revenue comes from non-English-speaking markets**, and only 33% of Steam users have English as their primary language. Localization is one of the few factors that **consistently influences Steam's algorithm** for visibility, making it not just a revenue expander but a discovery tool.

The highest-ROI languages for indie developers are **Simplified Chinese** and **German**, each capable of boosting revenue by roughly 30%. Brazilian Portuguese and Latin American Spanish round out the top tier. Localizing into the top six Steam languages (English, Simplified Chinese, Russian, Spanish, Brazilian Portuguese, German) covers approximately 85% of the Steam population.

Solo developers can achieve quality localization affordably using a hybrid approach: free platforms like **Crowdin** or **Localazy** enable community-driven translation, with a single professional editor per language reviewing the output. This cuts costs by 60–70% compared to full agency translation. A 5,000-word game localized into three languages costs approximately $2,100 through an agency, $1,200 through freelancers, or just $450 using the hybrid model.

The critical technical requirement is **internationalization from Day 1**: never hardcode strings, store all text in external files, use UTF-8 encoding, and plan for text expansion (German/French text runs 30–40% longer than English). Retrofitting localization support is far more expensive than building it in from the start.

---

## 8. Tax and legal infrastructure costs less than most developers fear

The recommended business structure for most solo developers follows a clear progression. Start as a **sole proprietorship** (free, default status) while pre-revenue, form a **single-member LLC** ($35–$500 depending on state) when launching commercially, and consider an **S-Corp election** only when net income consistently exceeds $60,000–$80,000 per year, where the self-employment tax savings justify the additional administrative complexity.

Both Roblox DevEx and Steam income are classified as **self-employment income**. Developers receive Form 1099-NEC from Roblox (for $600+) and Form 1099 from Valve. The combined tax burden — self-employment tax (15.3%), federal income tax (10–37%), and state income tax (0–13.3%) — means solo developers should **set aside 30–35% of all earnings** for taxes. Quarterly estimated payments are required to avoid penalties.

**Sales tax is largely handled by the platforms.** Steam, Roblox, Apple, and Google all collect and remit sales tax and international VAT on behalf of developers. This only becomes the developer's responsibility for direct sales through their own website. Similarly, international VAT obligations are managed by the platforms for marketplace transactions.

Trademarking a game name costs **$350 per class** for DIY filing (Class 9 for downloadable games, Class 41 for online entertainment services) and takes 12–18 months. About 80% of applications receive an Office Action, so attorney assistance ($750–$3,000 additional) improves success rates significantly. COPPA compliance is critical for games targeting children, with penalties up to $50,349 per violation — Epic Games paid $520 million in 2022 for violations.

Deductible expenses include game engine licenses, software subscriptions, asset purchases, marketing costs, professional services, conference travel, and a home office deduction (simplified method: $5/sq ft, maximum $1,500). Game purchases for competitive research are also deductible with proper documentation. The R&D tax credit (IRC Section 41) can apply to game development activities and offset up to $500,000 in tax liability.

---

## 9. Burnout is the default outcome, not an exception

The game industry's burnout crisis is well-documented but poorly addressed for solo developers specifically. The IGDA Developer Satisfaction Survey 2023 found that **28% of developers experience crunch** and an additional **25% work extended hours** they "just didn't call crunch." Self-employed developers worked longer hours than employees — only 13% of self-employed developers maintained standard 40–44 hour weeks versus 49% of employees. At GDC 2024, researchers Tim Stobo and Lis Moberly — both burnout victims themselves — presented data showing developers "may be crunching less, but are still being devastated by occupational burnout."

Solo developers face a unique constellation of burnout triggers. **Context switching** across 8–10 distinct roles (designer, programmer, artist, sound engineer, marketer, community manager, business administrator, legal counsel) is identified as a primary driver. **Isolation** amplifies every stressor — there's no team for emotional support, rubber-ducking, or sharing setbacks. **Financial stress** compounds everything: with 56% self-funding and median game revenue of $1,200, the economic anxiety is constant.

The academic concept of **"cruel optimism"** (Cote and Harris, 2023) describes how passion-driven overwork is reframed as "good crunch" while carrying "many, if not all, of the issues that result from bad crunch." This creates a self-perpetuating cycle where suffering is valorized. Eric Barone (Stardew Valley) worked approximately 70 hours per week for 4.5 years, experiencing "significant burnout and financial strain." His partner worked two jobs to support them. Developer Khang Nguyen poured 6 years into Cry of Athena, eventually relying on food banks and considering leaving game development entirely. These aren't aberrations — they're representative experiences obscured by survivorship bias.

Evidence-based strategies center on three controllable factors. **Scope** is the most critical: nearly every burnout story involves a project too ambitious for available resources. Aggressive scope reduction, MVP-focused development, and a strict "no, unless" approach to new features are the strongest preventive measures. **Connection** is second: joining developer communities, finding mentors (Limit Break Mentorship, Take This), attending game jams for social contact, and working from co-working spaces all reduce isolation's toll. **Structure** is third: strict working hours with start/end rituals, physical workspace separation between work and rest, weekly rest days, and the Pomodoro Technique (25 minutes focused work, 5-minute breaks) all create sustainable rhythms.

The psychological toll of negative reviews deserves special attention. One indie developer described their game's rating plummeting from "Mostly Positive" to "Mixed" overnight, with people telling them "very nasty things, much of which was entirely unnecessary. It put me in a very stressful place, and it was hard for me to focus on anything else." Review bombing by scam curator accounts, toxic community interactions, and the constant comparison pressure of #ScreenshotSaturday culture compound the mental health burden. **Take This** (takethis.org) and **Safe In Our World** are the primary game-industry-specific mental health organizations, though neither offers extensive solo-developer-specific programming — a gap in the ecosystem.

---

## 10. Mobile and web platforms offer alternatives worth evaluating

The mobile game market exceeds **$126 billion** in 2025, but the economics are forbidding for solo developers. Cost per install ranges from $1.50 (hyper-casual Android) to $6.00 (RPG iOS), and sustainable economics require lifetime value exceeding 3× CPI. For a solo developer without a marketing budget, paid user acquisition is simply unaffordable. Organic discovery on mobile app stores is nearly impossible without investment.

However, the revenue share comparison favors mobile over Roblox for developers under $1M in revenue. Both Apple (Small Business Program) and Google (first $1M tier) charge **15%** — meaning developers keep 85% versus Roblox's approximately 25%. The trade-off is that Roblox provides free hosting, distribution, and a built-in audience of 80+ million daily active users, while mobile requires the developer to build everything and find their own players.

**HTML5/web games are experiencing a quiet renaissance.** The 2025 State of the Game Industry report found **16% of developers** are working on browser game releases — the highest in a decade, up from 10% in 2024. Web games offer zero-friction play (click to start), SEO discoverability, no app store gatekeeping, and cross-platform compatibility by default. Phaser 5 dominates 2D web development (~65% market share), and WebAssembly enables near-native performance. The primary limitation is lower revenue per user and high churn rates.

Progressive Web Apps (PWAs) function as installable web games but face significant limitations: non-intuitive installation process, restricted APIs on iOS, no app store presence, and insufficient performance for graphics-intensive titles. They're best suited as a supplement for casual/turn-based games, not a primary distribution strategy.

For cross-platform engine selection, **Unity** remains the safest choice for solo developers targeting multiple platforms (25+ export targets, largest asset store). **Godot** is the best free option for 2D games, though it lacks native console export. Unity's controversial runtime fee was fully revoked in September 2024.

---

## 11. Roblox Luau architecture determines long-term maintainability

The most consequential technical decision for Roblox developers is adopting **Single-Script Architecture with ModuleScripts** from day one. Most front-page Roblox games (Adopt Me, Brookhaven) use this pattern: one Server Script and one LocalScript that `require()` ModuleScripts for all game logic. This provides controlled execution order, shared data structures, better performance, and dramatically easier maintenance compared to the common beginner mistake of scattering individual scripts throughout the workspace.

For data persistence, **ProfileService** (or its successor ProfileStore) is strongly recommended over raw DataStoreService. The library provides session-locking (preventing data duplication from multi-server access), automatic retry on throttling, built-in data versioning for migrations, and periodic auto-saves. Raw DataStoreService lacks all of these protections, making data loss a near-certainty at scale. DataStore throttling limits — 60 + (numPlayers × 10) requests per minute for both reads and writes — catch many new developers off guard.

Common technical mistakes that derail new Roblox developers include confusing server and client code (using `Players.LocalPlayer` in server scripts), not using `WaitForChild()` for replicated objects, placing scripts in wrong containers, using deprecated `wait()` instead of `task.wait()`, failing to wrap DataStore calls in `pcall()`, overusing global variables, not disconnecting event connections (causing memory leaks), and importing Free Models without inspecting for malicious backdoor scripts.

Performance optimization for lower-end devices requires keeping **part count under 75,000**, enabling StreamingEnabled for larger games, setting MeshPart RenderFidelity to "Performance" or "Automatic," anchoring all stationary parts, and hollowing out terrain. The MicroProfiler (Ctrl+F6) is the essential profiling tool. For entity-heavy games with overlapping behaviors, the **Matter** or **Jecs** ECS libraries offer clean composition-over-inheritance patterns.

---

## 12. What sustainable solo development actually requires

The data paints a consistent picture across all 12 dimensions researched. Solo game development is not primarily a technical challenge — it's an endurance challenge played against unfavorable odds in a winner-take-all market. The median outcome is financial loss, and the modal outcome is an abandoned project.

But the data also reveals clear, actionable strategies that improve odds significantly. **Second games sell 40% better** than first games, and third games sell 24% better than second — experience compounds. Published games sell **6× more** copies than self-published ones. Games with 500+ engaged Discord followers achieve conversion rates 25–40% higher. Localization into Simplified Chinese and German each boost revenue by ~30%. Accessibility features open the game to 20%+ more potential players. These are multiplicative advantages available to anyone willing to invest the effort.

The critical reframe is this: solo game development is viable as a long-term skill-building practice with occasional commercial upside, but it is not a reliable income source for the vast majority of practitioners. The developers who succeed almost universally share three traits — they shipped multiple projects before their hit, they scoped aggressively small, and they treated marketing as equal in importance to development. The ones who burned out almost universally share three different traits — they worked on a single over-ambitious project, they isolated themselves, and they treated their identity and their game as the same thing.

Plan for the median outcome. Budget for the realistic timeline. Build the business infrastructure early. Protect your mental health as fiercely as you protect your codebase. And if, against the odds, your game breaks through — you'll be structured, sustainable, and ready to capitalize on it.

---

## Quick-reference benchmarks

| Metric | Reality check |
|--------|--------------|
| Median Steam indie game lifetime revenue | ~$1,200 |
| Median Roblox DevEx annual payout | $1,575 |
| Steam games earning <$5,000 lifetime | 80% |
| Steam releases achieving "success" (1K+ reviews) | 2.4% |
| Roblox developer effective revenue share (F2P) | 19–29% |
| Mobile D1 retention (median, all genres) | 22.9% |
| F2P conversion rate (typical) | 1–5% |
| Developers whose last game lost money | 62% |
| Developers experiencing crunch/extended hours | 53% |
| Solo devs earning >$100K/year | 15% |
| Gamers with disabilities | 20–30% |
| Steam users with non-English primary language | 67% |
| Recommended tax set-aside (US self-employment) | 30–35% |
| LLC formation cost (most states) | $35–$500 |
| Trademark filing (single class, DIY) | $350+ |
| Minimum Steam wishlists for viable launch | 7,000 |