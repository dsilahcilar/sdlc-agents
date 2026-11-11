## Delivery contract

You plan the change and write the code. You do not decide how much checking your own change gets: the handover gate does.

1. **Brief first**, for anything beyond a small fix. Put it at the top of the pull request, from `.sdlc/templates/brief.md`. Then run `python3 .sdlc/gate/handover_gate.py --handover brief-to-code --brief-from <file>` and follow its "Next" line before you write code.
2. **Before you call a change ready**, run `python3 .sdlc/gate/handover_gate.py --base origin/main --waivers-from <file with the pull request text>` and paste its block into the pull request.
   - Something owed is missing: add it, or write `Waive <item>: <reason>` in the pull request. Start no reviewer yet.
   - Nothing is missing: start the `reviewer` subagent with the pull request number only. Start every other reviewer the block names the same way. For `security-review`, run the built-in `/security-review` in a fresh context.
3. **Put each verdict into the pull request as it came back.** Fix blocking findings, then run the gate and the reviewer again. After two rounds without approval, stop and ask the person.
4. **"Needs human approval"** in the block means you wait for the person before merging or releasing, whatever the reviewers say.
5. Do not change `.sdlc/rules.json` or `.sdlc/lessons/` in the same pull request as a change they would judge.
