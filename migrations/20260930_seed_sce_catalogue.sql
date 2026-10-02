-- Story Block Catalogue — seed the 185 entries defined in the development brief.
--
-- ON CONFLICT DO NOTHING keyed on (name, category) makes this re-runnable, so a
-- later revision can append or correct individual rows without wiping existing
-- ones. Retiring an entry is done with active = FALSE, not a delete, because
-- story blocks reference these ids.
--
-- prompt_questions holds the two questions from the brief, one per line.

-- ============================================================
-- 1. LitRPG
-- ============================================================
INSERT INTO sce_catalogue_entries (name, category, purpose, prompt_questions, default_color) VALUES
('System arrival or intrusion', 'LitRPG', 'Break normal life and impose a new reality.', 'What is lost immediately?
What is strange or absurd about the announcement?', '#22c55e'),
('Onboarding', 'LitRPG', 'Teach essential rules while the character is under pressure.', 'Who or what conducts it?
What important information is omitted?', '#22c55e'),
('Interface reveal', 'LitRPG', 'Make the invisible system visible.', 'What surprises the character?
What does the interface misunderstand?', '#22c55e'),
('Character sheet', 'LitRPG', 'Establish measurable strengths, weaknesses and anomalies.', 'Which stat embarrasses or frightens the character?
Which number looks wrong?', '#22c55e'),
('Stat translation or toggle', 'LitRPG', 'Compare two rule systems or identities.', 'What changes when the character switches systems?
What becomes unreliable?', '#22c55e'),
('First rule learned', 'LitRPG', 'Give the character one usable piece of knowledge.', 'How is it discovered through action rather than explanation?', '#22c55e'),
('Hidden rule', 'LitRPG', 'Reward attention and reframe earlier events.', 'What clue makes the discovery fair?
Who already knew?', '#22c55e'),
('Class or path choice', 'LitRPG', 'Turn personality into a consequential mechanical decision.', 'Which choice looks safest?
Which option reveals the real character?', '#22c55e'),
('Class rejected', 'LitRPG', 'Demonstrate independence or mistrust of the System.', 'Why is the recommended class wrong?
What is sacrificed by refusing it?', '#22c55e'),
('Class evolution', 'LitRPG', 'Mark a major identity and capability change.', 'What is gained?
What becomes harder to retain?', '#22c55e'),
('Specialisation', 'LitRPG', 'Narrow the build while creating distinct strengths.', 'What capability improves?
What options are lost?', '#22c55e'),
('Quest issued', 'LitRPG', 'Create a clear short-term objective.', 'Who benefits?
What is hidden in the wording?', '#22c55e'),
('Quest changed', 'LitRPG', 'Disrupt the expected objective.', 'Did the System react to the character, or was the original quest dishonest?', '#22c55e'),
('Quest failed', 'LitRPG', 'Deliver consequences and prevent effortless progression.', 'What remains salvageable?
What new problem replaces the reward?', '#22c55e'),
('Quest completed', 'LitRPG', 'Close a small arc and open a new decision.', 'Is the reward worth the cost?
Who notices the completion?', '#22c55e'),
('First kill or first win', 'LitRPG', 'Establish the action-to-progression loop.', 'What does victory cost emotionally or physically?', '#22c55e'),
('Experience gain', 'LitRPG', 'Confirm measurable progress.', 'Is the amount fair?
What behaviour is the System encouraging?', '#22c55e'),
('Level-up', 'LitRPG', 'Deliver visible progress and reader reward.', 'What becomes possible?
What remains impossible?', '#22c55e'),
('Stat allocation', 'LitRPG', 'Force a meaningful trade-off.', 'Immediate survival or long-term build?
What stat choice reveals character?', '#22c55e'),
('Skill unlock', 'LitRPG', 'Add a new tactic or identity shift.', 'Why this skill?
What limitation prevents it solving everything?', '#22c55e'),
('Skill test', 'LitRPG', 'Demonstrate a new ability in a controlled situation.', 'What unexpected side effect appears?', '#22c55e'),
('Ability failure', 'LitRPG', 'Show the edge of the rules and stop repetition.', 'Was it countered, exhausted, misread or used in the wrong world?', '#22c55e'),
('Cooldown or resource limit', 'LitRPG', 'Give power a usable cost.', 'What happens when the ability is needed before it recovers?', '#22c55e'),
('Ability used creatively', 'LitRPG', 'Reward imagination rather than raw power.', 'What non-obvious function does the character discover?', '#22c55e'),
('Ability combination', 'LitRPG', 'Pay off several earlier mechanics together.', 'Which abilities were never intended to work together?', '#22c55e'),
('System exploit', 'LitRPG', 'Reward curiosity while creating later danger.', 'Is it a glitch, trap or intended secret?
Who detects its use?', '#22c55e'),
('Achievement or title', 'LitRPG', 'Let the System interpret behaviour, often badly.', 'Is it useful, insulting, dangerous or all three?', '#22c55e'),
('Loot drop', 'LitRPG', 'Turn victory into a decision.', 'Equip, sell, hide, trade or give away?', '#22c55e'),
('Loot reveal', 'LitRPG', 'Create anticipation and disclose new information.', 'Who recognises the item?
What does it imply?', '#22c55e'),
('Loot box or reward chest', 'LitRPG', 'Supply excitement, comedy, temptation or disappointment.', 'Can the worst-looking reward become important later?', '#22c55e'),
('Cursed or compromised item', 'LitRPG', 'Offer power with an accumulating cost.', 'When does the drawback first appear?
Why keep using it?', '#22c55e'),
('Crafted item', 'LitRPG', 'Reward preparation, knowledge and collected materials.', 'What failed before this success?
Who contributed?', '#22c55e'),
('Crafting failure', 'LitRPG', 'Establish rules and make eventual success earned.', 'What resource is wasted?
What useful knowledge remains?', '#22c55e'),
('Merchant or shop', 'LitRPG', 'Introduce economy and difficult trade-offs.', 'What cannot be bought?
What price is not money?', '#22c55e'),
('Currency discovery', 'LitRPG', 'Show what the new world values.', 'How is it earned?
Why might spending it be dangerous?', '#22c55e'),
('Inventory problem', 'LitRPG', 'Turn possessions into a practical obstacle.', 'What must be abandoned?
What item is mistakenly overlooked?', '#22c55e'),
('Companion or summon', 'LitRPG', 'Add tactical possibilities and emotional attachment.', 'What does it want?
What does losing or restoring it cost?', '#22c55e'),
('Companion evolution', 'LitRPG', 'Reflect the character''s growth in another being.', 'Does the evolution improve the relationship or make it unsettling?', '#22c55e'),
('Party formation', 'LitRPG', 'Make different abilities and personalities interact.', 'Why do these people need one another?
Who does not belong?', '#22c55e'),
('Party role revealed', 'LitRPG', 'Make relationships visible through action.', 'Who protects whom?
Which roles conflict?', '#22c55e'),
('Team synergy', 'LitRPG', 'Reward trust and combined preparation.', 'Which abilities become stronger together?', '#22c55e'),
('Party fracture', 'LitRPG', 'Turn interpersonal conflict into tactical danger.', 'What belief, secret or reward splits the group?', '#22c55e'),
('Rival build', 'LitRPG', 'Create a mechanical and personal mirror.', 'Which choices did the rival make differently?', '#22c55e'),
('Rival victory', 'LitRPG', 'Prevent the protagonist owning every achievement.', 'What does the rival gain?
How does the public interpret it?', '#22c55e'),
('Leaderboard or ranking', 'LitRPG', 'Widen the world and reframe apparent success.', 'Who is impossibly far ahead?
Who notices the protagonist?', '#22c55e'),
('Broadcast or audience event', 'LitRPG', 'Turn private survival into public performance.', 'What is edited out?
What becomes a meme, scandal or lie?', '#22c55e'),
('Sponsor or patron', 'LitRPG', 'Add power, attention and obligation.', 'Why choose this character?
What behaviour is being encouraged?', '#22c55e'),
('Faction introduction', 'LitRPG', 'Expand progression into politics and allegiance.', 'What protection is offered?
What obedience is demanded?', '#22c55e'),
('Settlement or safe zone', 'LitRPG', 'Give progress a communal form.', 'Who controls entry?
What makes safety temporary?', '#22c55e'),
('Territory or base upgrade', 'LitRPG', 'Make accumulated effort visible in the world.', 'What improvement creates a new vulnerability?', '#22c55e'),
('Dungeon or contained zone', 'LitRPG', 'Create a sequence with distinctive rules.', 'What changes on entry?
Why can they not simply leave?', '#22c55e'),
('Trial or challenge room', 'LitRPG', 'Test a specific ability, belief or weakness.', 'Is the stated test the real test?', '#22c55e'),
('Environmental rule', 'LitRPG', 'Make location mechanically important.', 'What rule must be understood before fighting becomes possible?', '#22c55e'),
('Monster encounter', 'LitRPG', 'Test current abilities and establish danger.', 'What makes this creature different from a routine opponent?', '#22c55e'),
('Elite encounter', 'LitRPG', 'Show the danger hierarchy above normal threats.', 'What advantage stops the usual tactic working?', '#22c55e'),
('Boss encounter', 'LitRPG', 'Close a smaller arc and test the current build.', 'What rule makes the boss a puzzle rather than a larger monster?', '#22c55e'),
('Hidden boss phase', 'LitRPG', 'Invalidate the obvious plan.', 'What earlier clue foreshadowed the transformation?', '#22c55e'),
('Technical duel', 'LitRPG', 'Turn combat into a contest of knowledge and counters.', 'What must be understood rather than overpowered?', '#22c55e'),
('Ambush or ability counter', 'LitRPG', 'Remove the protagonist''s favourite solution.', 'Who studied the hero?
How is the signature power neutralised?', '#22c55e'),
('Defeat and escape', 'LitRPG', 'Preserve the threat and create a future goal.', 'What must be sacrificed to survive?', '#22c55e'),
('Death or failure penalty', 'LitRPG', 'Give loss a continuing mechanical shape.', 'What can be recovered?
What is permanently changed?', '#22c55e'),
('Power with a moral cost', 'LitRPG', 'Make progression challenge the character''s identity.', 'Who pays for the upgrade?
What line might be crossed?', '#22c55e'),
('Book-end unlock', 'LitRPG', 'Close the current objective while opening the next scale.', 'What new door appears only because the character succeeded?', '#22c55e')
ON CONFLICT (name, category) DO NOTHING;

-- ============================================================
-- 2. Story Rhythm and Tempo
-- ============================================================
INSERT INTO sce_catalogue_entries (name, category, purpose, prompt_questions, default_color) VALUES
('Action scene', 'Story Rhythm and Tempo', 'Increase speed, danger and immediate consequence.', 'What changes besides injuries?
Why must it happen now?', '#ef4444'),
('Short combat beat', 'Story Rhythm and Tempo', 'Add danger without turning every conflict into a set piece.', 'What new information or cost does the encounter create?', '#ef4444'),
('Chase or escape', 'Story Rhythm and Tempo', 'Create forward momentum and force rapid decisions.', 'What must be left behind?
Where does the escape lead?', '#ef4444'),
('Internal monologue', 'Story Rhythm and Tempo', 'Process events and reveal interpretation.', 'What is the character refusing to admit?
Is reflection changing a decision?', '#ef4444'),
('Character conversation', 'Story Rhythm and Tempo', 'Develop relationships while moving information or decisions.', 'What does each person want from the exchange?', '#ef4444'),
('Argument', 'Story Rhythm and Tempo', 'Externalise opposing values or plans.', 'Which side has the strongest argument?
What changes after it?', '#ef4444'),
('Humorous beat', 'Story Rhythm and Tempo', 'Release tension and reinforce voice.', 'Does the joke reveal character or world rather than pausing the story?', '#ef4444'),
('Rest or recovery', 'Story Rhythm and Tempo', 'Allow emotional and physical consequences to land.', 'What cannot be repaired during the pause?', '#ef4444'),
('Travel', 'Story Rhythm and Tempo', 'Move characters while developing world, relationship or anticipation.', 'What changes during the journey?
Why is it not merely transport?', '#ef4444'),
('Preparation', 'Story Rhythm and Tempo', 'Build expectation and demonstrate competence.', 'What part of the plan will later fail?', '#ef4444'),
('Planning scene', 'Story Rhythm and Tempo', 'Clarify intentions before action.', 'What disagreement or missing information complicates the plan?', '#ef4444'),
('Training or experimentation', 'Story Rhythm and Tempo', 'Show earned improvement and mechanical limits.', 'What fails?
What unexpected use is discovered?', '#ef4444'),
('Investigation', 'Story Rhythm and Tempo', 'Turn uncertainty into active discovery.', 'What question guides the search?
What answer creates a larger question?', '#ef4444'),
('Discovery', 'Story Rhythm and Tempo', 'Change what characters and readers understand.', 'Who understands its importance first?', '#ef4444'),
('Exposition or explanation', 'Story Rhythm and Tempo', 'Deliver necessary information.', 'Can it be attached to conflict, demonstration or discovery?', '#ef4444'),
('Worldbuilding moment', 'Story Rhythm and Tempo', 'Make the setting feel inhabited and specific.', 'What custom, inconvenience or contradiction makes the world real?', '#ef4444'),
('Decision', 'Story Rhythm and Tempo', 'Convert information into direction.', 'What is sacrificed by choosing?', '#ef4444'),
('Moral choice', 'Story Rhythm and Tempo', 'Reveal character under conflicting obligations.', 'What good outcome becomes impossible?', '#ef4444'),
('Reversal', 'Story Rhythm and Tempo', 'Change the apparent direction of the scene or sequence.', 'What assumption proves false?', '#ef4444'),
('Failure', 'Story Rhythm and Tempo', 'Remove certainty, resources or confidence.', 'What does the failure produce beyond delay?', '#ef4444'),
('Partial victory', 'Story Rhythm and Tempo', 'Reward effort while leaving a meaningful problem.', 'What was won, and what became worse?', '#ef4444'),
('Victory', 'Story Rhythm and Tempo', 'Resolve an objective and create consequences.', 'What does success attract, expose or cost?', '#ef4444'),
('Consequence', 'Story Rhythm and Tempo', 'Make earlier action matter.', 'Which previous choice caused this?
What new choice follows?', '#ef4444'),
('Quiet character moment', 'Story Rhythm and Tempo', 'Deepen attachment without major spectacle.', 'What small behaviour communicates the change?', '#ef4444'),
('Grief or processing', 'Story Rhythm and Tempo', 'Let loss affect future behaviour.', 'What does the character do rather than say?', '#ef4444'),
('Celebration', 'Story Rhythm and Tempo', 'Provide contrast and make the community worth protecting.', 'What threat or tension remains underneath?', '#ef4444'),
('Cliffhanger', 'Story Rhythm and Tempo', 'Create an urgent unanswered development.', 'Does it alter the story rather than merely stop the chapter?', '#ef4444'),
('Breather', 'Story Rhythm and Tempo', 'Reduce intensity before the next rise.', 'What useful emotional, relational or world work happens here?', '#ef4444')
ON CONFLICT (name, category) DO NOTHING;

-- ============================================================
-- 3. Set-Piece
-- ============================================================
INSERT INTO sce_catalogue_entries (name, category, purpose, prompt_questions, default_color) VALUES
('Boss battle', 'Set-Piece', 'Deliver a major mechanical and emotional test.', 'What phase, rule or cost distinguishes it?', '#ef4444'),
('Monster hunt', 'Set-Piece', 'Combine investigation, preparation and confrontation.', 'What does tracking reveal before the fight?', '#ef4444'),
('Ambush', 'Set-Piece', 'Destroy preparation and create immediate imbalance.', 'Why was the group vulnerable?', '#ef4444'),
('Rescue', 'Set-Piece', 'Combine urgency, protection and difficult priorities.', 'Who else must be saved?
What cannot be carried out?', '#ef4444'),
('Heist', 'Set-Piece', 'Build pleasure through planning, execution and reversal.', 'What is the real target?
Who changes the plan?', '#ef4444'),
('Infiltration', 'Set-Piece', 'Create suspense through restricted information and discovery.', 'What forces the infiltrator to improvise?', '#ef4444'),
('Siege', 'Set-Piece', 'Pay off community, preparation and accumulated defences.', 'Where is the overlooked weakness?', '#ef4444'),
('Duel', 'Set-Piece', 'Focus conflict into two opposing people or builds.', 'What makes them mirrors?
What counts as victory?', '#ef4444'),
('Tournament or public trial', 'Set-Piece', 'Combine spectacle, ranking and social consequences.', 'Who controls the rules?
What happens off the field?', '#ef4444'),
('Dungeon run', 'Set-Piece', 'Deliver escalating environments, attrition and rewards.', 'What unique rule governs the location?', '#ef4444'),
('Puzzle encounter', 'Set-Piece', 'Reward observation and understanding.', 'What clue has already been shown?', '#ef4444'),
('Survival sequence', 'Set-Piece', 'Strip goals back to endurance and resourcefulness.', 'What resource runs out first?', '#ef4444'),
('Disaster sequence', 'Set-Piece', 'Force simultaneous problems and triage.', 'What cannot be saved?
Who chooses priorities?', '#ef4444'),
('Social-media show or broadcast', 'Set-Piece', 'Turn events into edited public entertainment.', 'Who controls the story the audience sees?', '#ef4444'),
('Loot-box reveal', 'Set-Piece', 'Combine reward, spectacle and new complications.', 'What private information is exposed?', '#ef4444'),
('System-wide announcement', 'Set-Piece', 'Reframe local events within a larger world.', 'What new deadline, ranking or threat is introduced?', '#ef4444'),
('Trial of character', 'Set-Piece', 'Test values instead of raw ability.', 'What is the optimal choice, and why does the hero refuse it?', '#ef4444'),
('Escape through changing terrain', 'Set-Piece', 'Make the environment an active opponent.', 'What familiar route or rule stops working?', '#ef4444'),
('Final confrontation', 'Set-Piece', 'Combine the book''s learned abilities, relationships and choices.', 'Which earlier elements must work together?', '#ef4444')
ON CONFLICT (name, category) DO NOTHING;

-- ============================================================
-- 4. Character
-- ============================================================
INSERT INTO sce_catalogue_entries (name, category, purpose, prompt_questions, default_color) VALUES
('Character introduction', 'Character', 'Establish personality through behaviour.', 'What does the character do before the reader knows who they are?', '#a855f7'),
('Desire stated or demonstrated', 'Character', 'Give the character a direction.', 'What do they believe will make life better?', '#a855f7'),
('Fear revealed', 'Character', 'Establish what the character avoids.', 'How is avoidance already costing them?', '#a855f7'),
('Flaw in action', 'Character', 'Show a useful trait becoming damaging.', 'When does the strength become a weakness?', '#a855f7'),
('Competence moment', 'Character', 'Give the reader a reason to trust or enjoy the character.', 'What can they do that matters here?', '#a855f7'),
('Vulnerability moment', 'Character', 'Reveal a limit without removing agency.', 'Who witnesses it?
What changes between them?', '#a855f7'),
('Identity conflict', 'Character', 'Place old self and emerging self in opposition.', 'What power or role feels unlike them?', '#a855f7'),
('Temptation', 'Character', 'Offer an easier route with a meaningful price.', 'Why is saying no genuinely difficult?', '#a855f7'),
('Boundary or moral line', 'Character', 'Clarify what the character will not do.', 'What happens when that line becomes costly?', '#a855f7'),
('Mistake', 'Character', 'Let the character cause a real problem.', 'What belief produced the mistake?', '#a855f7'),
('Responsibility accepted', 'Character', 'Move the character from reaction to ownership.', 'What burden do they choose rather than inherit?', '#a855f7'),
('Sacrifice', 'Character', 'Prove priorities through cost.', 'What permanent thing is surrendered?', '#a855f7'),
('Realisation', 'Character', 'Change the character''s understanding.', 'Which earlier events suddenly mean something different?', '#a855f7'),
('New behaviour', 'Character', 'Demonstrate growth through action rather than declaration.', 'What would the earlier version of the character have done?', '#a855f7'),
('Character payoff', 'Character', 'Resolve or transform the central internal question.', 'How does the final choice answer the opening version of the character?', '#a855f7')
ON CONFLICT (name, category) DO NOTHING;

-- ============================================================
-- 5. Relationship
-- ============================================================
INSERT INTO sce_catalogue_entries (name, category, purpose, prompt_questions, default_color) VALUES
('First meeting', 'Relationship', 'Establish attraction, friction or usefulness.', 'What does each person misread about the other?', '#ec4899'),
('Practical alliance', 'Relationship', 'Join characters before emotional trust exists.', 'What terms or boundaries are agreed?', '#ec4899'),
('Banter', 'Relationship', 'Build chemistry and voice.', 'What is being avoided beneath the humour?', '#ec4899'),
('First trust', 'Relationship', 'Create a small but costly act of reliance.', 'What could the other person do with this vulnerability?', '#ec4899'),
('Shared victory', 'Relationship', 'Bond characters through competence.', 'What does each now respect in the other?', '#ec4899'),
('Shared failure', 'Relationship', 'Test blame, loyalty and honesty.', 'Who accepts responsibility?', '#ec4899'),
('Secret kept', 'Relationship', 'Create future strain.', 'Why does hiding it feel justified?', '#ec4899'),
('Secret revealed', 'Relationship', 'Reframe previous behaviour.', 'Does the truth repair or worsen the relationship?', '#ec4899'),
('Disagreement', 'Relationship', 'Give both characters valid but incompatible positions.', 'What value is each protecting?', '#ec4899'),
('Betrayal or apparent betrayal', 'Relationship', 'Break trust and redirect action.', 'Was the betrayal real, forced or misunderstood?', '#ec4899'),
('Separation', 'Relationship', 'Test whether the bond survives without proximity.', 'What does each realise while apart?', '#ec4899'),
('Rescue or protection', 'Relationship', 'Turn feeling into action.', 'Is help wanted?
What does protection cost?', '#ec4899'),
('Confession', 'Relationship', 'Replace implication with honesty.', 'Why can the truth no longer remain unspoken?', '#ec4899'),
('Reconciliation', 'Relationship', 'Create a changed relationship rather than restoring the old one.', 'What condition or apology makes it possible?', '#ec4899'),
('Found-family moment', 'Relationship', 'Make the group emotionally meaningful.', 'What ordinary act proves belonging?', '#ec4899'),
('Romantic progression', 'Relationship', 'Advance a slow-burn relationship.', 'What becomes possible now that was not possible before?', '#ec4899'),
('Relationship payoff', 'Relationship', 'Demonstrate the final form of the bond.', 'What choice can they now make together?', '#ec4899')
ON CONFLICT (name, category) DO NOTHING;

-- ============================================================
-- 6. Mystery, Foreshadowing and Payoff
-- ============================================================
INSERT INTO sce_catalogue_entries (name, category, purpose, prompt_questions, default_color) VALUES
('Question planted', 'Mystery and Payoff', 'Give the reader something specific to wonder about.', 'Who notices it, and who dismisses it?', '#f59e0b'),
('Hint', 'Mystery and Payoff', 'Move the reader slightly closer to the truth.', 'Does it support more than one interpretation?', '#f59e0b'),
('Repeated hint or echo', 'Mystery and Payoff', 'Confirm that an earlier detail matters.', 'What changes between the first and second appearance?', '#f59e0b'),
('Physical clue', 'Mystery and Payoff', 'Give mystery a tangible form.', 'Who can recognise or misread it?', '#f59e0b'),
('Behavioural clue', 'Mystery and Payoff', 'Reveal truth through inconsistent action.', 'What does the person do that contradicts their words?', '#f59e0b'),
('Missing information', 'Mystery and Payoff', 'Make an absence meaningful.', 'Who benefits from the gap?', '#f59e0b'),
('Red herring', 'Mystery and Payoff', 'Create a plausible wrong explanation.', 'Is it connected to a real secondary truth?', '#f59e0b'),
('False meaning', 'Mystery and Payoff', 'Let the correct evidence support the wrong conclusion.', 'What assumption causes the misreading?', '#f59e0b'),
('Suspicion changes target', 'Mystery and Payoff', 'Redirect investigation without resetting it.', 'Which earlier clue now looks different?', '#f59e0b'),
('Partial reveal', 'Mystery and Payoff', 'Answer one question while opening another.', 'What new question is more important?', '#f59e0b'),
('Full reveal', 'Mystery and Payoff', 'Reinterpret prior events.', 'Which hints become obvious in hindsight?', '#f59e0b'),
('Payoff', 'Mystery and Payoff', 'Deliver the result of an earlier setup or promise.', 'Has enough time and development passed for it to feel earned?', '#f59e0b'),
('Consequence of reveal', 'Mystery and Payoff', 'Ensure knowledge changes behaviour or stakes.', 'What can no longer continue as before?', '#f59e0b'),
('Callback', 'Mystery and Payoff', 'Reward memory without being necessary for comprehension.', 'How has the meaning changed?', '#f59e0b'),
('Easter egg', 'Mystery and Payoff', 'Add an optional layer for attentive readers.', 'Does the story still work if it is missed?', '#f59e0b'),
('Series mystery', 'Mystery and Payoff', 'Preserve a larger unanswered question beyond the book.', 'What partial answer makes continued mystery satisfying?', '#f59e0b')
ON CONFLICT (name, category) DO NOTHING;

-- ============================================================
-- 7. World and Social
-- ============================================================
INSERT INTO sce_catalogue_entries (name, category, purpose, prompt_questions, default_color) VALUES
('New location', 'World and Social', 'Establish distinctive opportunities and problems.', 'What can happen here that cannot happen elsewhere?', '#14b8a6'),
('Local custom', 'World and Social', 'Make the world inhabited rather than described.', 'How does an outsider get it wrong?', '#14b8a6'),
('Rule of society', 'World and Social', 'Show power through everyday consequences.', 'Who benefits and who is excluded?', '#14b8a6'),
('Authority encounter', 'World and Social', 'Personalise institutions and rules.', 'Is the authority competent, compromised or trapped?', '#14b8a6'),
('Faction conflict', 'World and Social', 'Create competing visions of safety or progress.', 'What does each side genuinely get right?', '#14b8a6'),
('Public reaction', 'World and Social', 'Show how private action becomes reputation.', 'What version of events spreads?', '#14b8a6'),
('Rumour', 'World and Social', 'Move distorted information through the world.', 'Who started it?
Who profits from believing it?', '#14b8a6'),
('News or broadcast', 'World and Social', 'Deliver wider developments with bias or framing.', 'What is omitted or edited?', '#14b8a6'),
('Community moment', 'World and Social', 'Show what is being built or protected.', 'What ordinary need matters after the spectacle?', '#14b8a6'),
('Prejudice or misunderstanding', 'World and Social', 'Test the community''s values.', 'What evidence challenges the assumption?', '#14b8a6'),
('Economic pressure', 'World and Social', 'Turn worldbuilding into practical decisions.', 'What has become scarce, valuable or controlled?', '#14b8a6'),
('Political decision', 'World and Social', 'Make collective consequences visible.', 'Who gets a voice?
Who bears the cost?', '#14b8a6')
ON CONFLICT (name, category) DO NOTHING;

-- ============================================================
-- 8. Horror and Dark-Fiction
-- ============================================================
INSERT INTO sce_catalogue_entries (name, category, purpose, prompt_questions, default_color) VALUES
('Unease', 'Horror and Dark-Fiction', 'Signal that something is wrong before danger is understood.', 'What ordinary detail is subtly incorrect?', '#6d28d9'),
('Impossible detail', 'Horror and Dark-Fiction', 'Break the reader''s model of reality.', 'Who notices first?
Who refuses to believe it?', '#6d28d9'),
('Dread escalation', 'Horror and Dark-Fiction', 'Make a known threat approach without immediate release.', 'What reduces the available options?', '#6d28d9'),
('Isolation', 'Horror and Dark-Fiction', 'Remove help, witnesses or certainty.', 'Is the character physically or emotionally isolated?', '#6d28d9'),
('Body horror', 'Horror and Dark-Fiction', 'Make transformation intimate and costly.', 'What remains recognisably human?', '#6d28d9'),
('Contamination', 'Horror and Dark-Fiction', 'Turn contact, knowledge or place into danger.', 'How does it spread?
What does suspected infection do socially?', '#6d28d9'),
('Unreliable perception', 'Horror and Dark-Fiction', 'Make the character doubt what can be trusted.', 'What evidence remains objective?', '#6d28d9'),
('Discovery of remains', 'Horror and Dark-Fiction', 'Convert implied danger into physical evidence.', 'What do the remains reveal about the threat?', '#6d28d9'),
('Safe place violated', 'Horror and Dark-Fiction', 'Remove a source of security.', 'What rule or mistake allowed entry?', '#6d28d9'),
('Familiar person changed', 'Horror and Dark-Fiction', 'Combine loss, recognition and threat.', 'Is any part of the person still present?', '#6d28d9'),
('Mercy choice', 'Horror and Dark-Fiction', 'Force survival and compassion into conflict.', 'What does refusing or acting cost?', '#6d28d9'),
('Horrific reveal', 'Horror and Dark-Fiction', 'Reframe events through a disturbing truth.', 'Which earlier details become worse in hindsight?', '#6d28d9'),
('Aftermath', 'Horror and Dark-Fiction', 'Allow horror to alter behaviour and relationships.', 'What cannot be mentally or physically cleaned away?', '#6d28d9')
ON CONFLICT (name, category) DO NOTHING;