# AI Experiment

Goal of this experiment is to show that the results can be completely different based on the models and prompts you use and how you generally work with GenAI.
Additionally I want to show advantages and disadvantages of using LLMs to generate code as part of your daily workflow and if it can be used to help with productivity.

## Plumber Puzzle Game

This experiment is about developing a "Plumber Puzzle Game" where you have a grid of tiles and you have a defined start and end tile and you have to connect start and and via rotating each tile by 90°. If everything is connected properly, you can continue with the next puzzle.

I'm using the **Godot Engine 4.6** for this as I've the most experience in this game engine. Additionally I've used a Godot MCP (which didn't work for the `opus-4.5-vibe` branch btw. - I had an error in my MCP configuration) and Claude Code inside Zed IDE.

## Models

I have a Claude subscription, so I've used the Claude models for this experiment. Claude Opus 4.5 is also one of the best coding models out there (4.6 just got released which is a bit better), while Claude Haiku 4.5 is a model for quick responses without much thinking etc.

As I don't want to invest that much time into this experiment, I've just did those 3 attempts. It would be interesting to see how other models (especially open source models like Kimi K2.5 for example) perform!

## Prompt

This was the (german) starting prompt for the `opus-4.5-vibe` and the `haiku-4.5-vibe` branches:

> Implementiere ein "Plumber Puzzle Game". Wenn Start- und Endpunkt miteinander verbunden sind, ist das Puzzle gelöst.

For the `opus-4.5-vibe-and-plan` branch, I've documented my prompts here: https://github.com/Paragrimm/AI.PlumberPuzzleGame/tree/opus-4.5-vibe-and-plan/_claude/Prompts (I've renamed the otherwise hidden directory `.claude` to `_claude` so I could upload it directly in the GitHub UI (I'm lazy, I know :D))

## Planning

In the `opus-4.5-vibe-and-plan` branch I did a longer planning phase where I wanted to define the architecture, coding style and "brainstorm" the possibilities especially regarding generating puzzles compared to manually defining these.

As you can see in the Prompt files, the AI offered me a - imho - bad code structure where code and scenes where scattered around the project in their respective folders, so I told the LLM that I'd prefer a structure where everything that is related to each other is inside one directory (DDD does that quite well in my experience).

The benefit is also that the AI has an easier time to understand the structure and the context doesn't pollute that much by analyzing every file and folder as it "might contain relevant information". A clear structure helps you as a human developer as well as the LLM.

## Advantages

Besides the point I previously mentioned (clear structure helps you as a human and the LLM), I want to point out several further advantages of AI use:

- Documentation! This project already is well documented due to the implementation plan
- As LLMs provide better results if you write "clean code" and you use clear variable and method/function names, it's also a benefit for you as you should generally write clean code and the usage of AI favors that
- Understanding: I've worked on a similar game lots of years ago and I've made lots of notes back then on how I'd implement an algorithm that checks whether the puzzle is solved or not (it was really unoptimized lol), therefore I had a rough idea on how that could work. If I'd had to start that project on my own, I'd probably use a similar approach. AI showed me another approach that instantly made sense: AI said that he'd use simple pathfinding from Start to End and he'd put the corresponding tiles along the way and just randomize the rotation. This totally made sense and I haven't thought about that initially! This information highly influences the code structure as the data and logic layer depend on that.
- "Emotional distance to your code": There is something called "sunk cost fallacy" and it happens (at least for me...) with code you've written by yourself aswell. Sometimes there is a "barrier" you need to overcome in order to do a full refactor of some classes or whatever. If you use generated code (and I'd not advise to generate "everything"!), you're not as emotionally attached to the code and therefore it's easier to be productive and just do the refactor

**Of course these advantages have more or less value depending on the project you're working on! So take it with a grain of salt! There will be uses or projects where you don't have that "aha-effect" like I had and there will be moments where AI tells you something and you think "Oh that's nice!" and in the end, it actually isn't nice. But well, to validate the approach or idea, you have to try that out anyways, right?**

## Disadvantages

Here we go!

- You should NOT rely on AI! A LLM should always be cour "copilot" and should not take the drivers seat for any serious project (it might be fine for small prototypes or simple tasks or whatever though - "it depends")! It's YOUR project and YOU should understand it. If the LLM understands the project better than you, you did something fundamentally wrong and you'll not be able to work with the results for a long time (fix-loop)
- "cognitive offload" should not be underestimated! It's tempting to just throw a mentally demanding task at a LLM so it can try to solve it for you, but this way, you'll just get "rusty" and your coding skills do not improve. Remember: the LLM results directly correlate with your skill as a coder! If you have lots of experience and you know exactly how something would be ideally implemented and what trade-offs are there etc. you automatically get better results if you use a LLM. You can then clearly articulate what you mean and what you have in mind, while someone who is less experienced, might just find "general words" for that which will probably result in hallucinations
- Clear communication is needed (imho more an advantage, but I'll list it here, as it correlates with hallucinations): the clearer you communicate, the clearer the result. The results for the `opus-4.5-vibe` and `haiku-4.5-vibe` branches show that. The models interpreted a lot into that single prompt. There are buttons around that, sometimes even statistics, one made SVG assets for the game and whatnot. This wasn't defined AT ALL! Therefore it's a HUGE waste of resource that doesn't happen if you clearly define what you expect from the result
- Speaking of resources: Anthropic is no sage or whatever and the training of their models have a huge impact on the environment (the data centers are in america and Fuhrer Trump doesn't value the environment -> 1+1 right?). Based on [this article](https://www.simonpcouch.com/blog/2026-01-20-cc-impact/) I assume that I've probably used ~50Wh which might be comparable to the energy consumption of my gaming PC while coding (I actually don't know...), therefore it's like I'd turn on another computer in america but worse as my PC runs with green electricity and the "computer in america" clearly doesn't. _My position is that you have to keep in mind that 1 person can spin up **N** Agents, which means that corporations are **clearly** the problem and the use for small/indie devs is negligible, especially compared to eating meat and driving cars (you can only stuff so much meat in your mouth and you can only drive one car at once...). And for the sake of completion: I neither eat meat, nor do I have a drivers license..._

The same statement as for the advantages also apply here... in the end, it's a tool where you put in natural language and you receive natural language + code. As with an usual workday as a coder, the output is different based on lots of factors (prompt, context, project structure, clean code/architecture, maybe even commit history, used tools, ...)

## Summary

I don't want to advocate for the use of AI or whatever, but I do actually think that there's a lot of misinformation regarding that topic and I want to encourage a reflected and constructive conversation about tools like that, without being "Anti" or absolutely "Pro" AI. LLMs have lots of disadvantages in general (not just regarding code generation)!

I certainly hope that it helps anybody to get a better understanding of the technology and maybe learns something along the way.

I'd be especially interested in PRs that add results from other AI models and I'd also love someone who implements a game like that fully without AI, so the comparison gains value :).

**This is the time I've spent:**

- `opus-4.5-vibe` branch: <10min (~4min implementing, ~5min testing the result and iterate on a fix that wasn't solved...)
- `haiku-4.5-vibe` branch: ~10min (~8min implementing, short test phase where I realized that the result is garbage...)
- `opus-4.5-vibe-and-plan` branch: ~60min (~30min planning, ~15-20min implementing, ~5-10min testing/playing)
