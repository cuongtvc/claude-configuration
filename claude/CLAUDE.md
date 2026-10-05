## Subagent models

- Search and exploration ("where is X", "what calls Y", map a directory): when spawning the built-in Explore agent, pass `model: "sonnet"`.
- Research (read docs or code, compare options, conclude): use general-purpose with no `model` override, so it runs on the main model.
