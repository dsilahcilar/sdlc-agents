## Delivery contract

You plan the change and write the code. You do not decide how much checking your own change gets: the handover gate does. The "Handover gate" job runs the same gate on the pull request and stays red while something the change owes is not there.

1. **Brief first**, for anything beyond a small fix. Put it at the top of the pull request, from `.sdlc/templates/brief.md`. Then run `python3 .sdlc/gate/handover_gate.py --handover brief-to-code --brief-from <file>` and follow its "Next" line before you write code.
2. **Before you call a change ready**, run `python3 .sdlc/gate/handover_gate.py --base origin/main --pull-request-from <file with the pull request text>` and paste its block into the pull request.
   - Something owed is missing: add it, or write `Waive <item>: <reason>` in the pull request. Where the block says a run counts, `Ran <item>: <what you ran and what it showed>` answers it too. Start no reviewer yet.
   - "Next: review by ...": start each reviewer the line names, as a subagent with the pull request number only. Where it cannot fetch the pull request itself, add the path of the file with its text. For `security-review`, run the built-in `/security-review` in a fresh context.
   - "Next: ready": nothing is waited for. Do not start a reviewer to be safe. The list of places the reviewer reads is kept in the rules, not decided per change.
3. **Put each verdict into the pull request as it came back.** Fix blocking findings, then run the gate and the reviewer again. Findings under `worth_fixing` do not hold the merge: fix them here if they are small, or say in the pull request where they go. After two rounds without approval, stop and ask the person.
4. **Record the review in one line** above its verdict, once the reviewer has approved or the person has decided what stays open: `Verdict <reviewer>: <what it said, and what you did about it>`. The gate waits for a reviewer until its line is there. Write it only for a review that ran.
5. **"Needs human approval"** in the block means you wait for the person before merging or releasing, whatever the reviewers say.
6. Do not change `.sdlc/rules.json` or `.sdlc/lessons/` in the same pull request as a change they would judge. Never change the gate, its rules or its workflow to get a pull request through.
