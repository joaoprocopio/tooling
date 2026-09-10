# The two axes

The briefs `pr-review` dispatches, and what a sub-agent must return for step 3 to check it and step 5 to post it.

A change can pass one axis and fail the other. Code follows every standard while implementing the wrong thing, or does exactly what the spec asked in a shape the repo forbids. The axes stay separate for the whole run, so neither masks the other, and nothing reranks them into one list.

## The output shape

Both briefs end with this. Step 3 anchors and checks a finding by these fields and step 5 posts it by them, so each brief asks for all eight.

| Field       | What it holds                                                        |
| ----------- | -------------------------------------------------------------------- |
| `file`      | the path as the diff spells it                                       |
| `text`      | the distinctive text of the line, which is what `pr.diff-line` takes |
| `side`      | new or old, since a removed line anchors on the old side             |
| `change`    | one line naming what to do, phrased as an instruction                |
| `evidence`  | the standard, the spec line, or the command output that proves it    |
| `axis`      | Standards or Spec                                                    |
| `blocker`   | whether it gates the merge                                           |
| `suggestion`| the replacement lines, when the fix is a known set of them           |

Ask for the line's text rather than its number: a sub-agent reads the local file, and a local number is not the number the diff carries.

## The spec source

Step 2 resolves this before dispatching, in this order:

1. Issue references in the commit messages and the PR description, fetched through whatever the repo documents for its tracker
2. A path the user passed
3. A spec file under `docs/`, `specs/`, or `.scratch/` matching the branch name or the feature
4. Nothing found, and the user says there is none: the Spec axis runs against the change's own claim about itself alone, and the report says so

## The standards source

Whatever the repo documents about how to write its code: `CONTRIBUTING.md`, `CODING_STANDARDS.md`, `CLAUDE.md`, `AGENTS.md`, a linter config that encodes a house rule. Skip anything tooling already enforces, since a failing check reports it without a thread.

On top of what the repo documents, the Standards axis carries the smell baseline below, which applies even to a repo that documents nothing. Two rules bind it:

- **The repo overrides.** A documented standard wins. Where the repo endorses what the baseline would flag, the baseline is silent.
- **Every smell is a judgement call**, labelled as one ("possible Feature Envy"), never a hard violation. A documented standard can be breached hard; a smell is a question.

## The smell baseline

Each reads *what it is* → *what to do about it* (Fowler, _Refactoring_, ch. 3):

- **Mysterious Name**: a function, variable, or type whose name hides what it does or holds. → Rename it; when no honest name comes, the design is the problem.
- **Duplicated Code**: the same logic shape in more than one hunk or file of the change. → Extract the shape and call it from both.
- **Feature Envy**: a method that reaches into another object's data more than its own. → Move the method onto the data it envies.
- **Data Clumps**: the same three or more fields or parameters travelling together. → Bundle them into the type they are asking to become.
- **Primitive Obsession**: a primitive or string standing in for a domain concept. → Give the concept its own small type.
- **Repeated Switches**: the same switch or if-cascade on the same type, recurring across the change. → Replace it with polymorphism, or one map both sites read.
- **Shotgun Surgery**: one logical change forcing an edit in three or more files at once. → Gather what changes together into one module.
- **Divergent Change**: one file edited for two or more unrelated reasons. → Split it so each part changes for one reason.
- **Speculative Generality**: abstraction, parameters, or hooks for needs the spec does not have. → Delete it and inline back until a real need shows.
- **Message Chains**: long `a.b().c().d()` navigation the caller should not depend on. → Hide the walk behind one method on the first object.
- **Middle Man**: a class or function that mostly delegates onward. → Cut it and call the real target.
- **Refused Bequest**: a subclass that ignores or overrides most of what it inherits. → Drop the inheritance and compose instead.

## The Standards brief

Give the sub-agent the diff command, the commit list, the standards-source files, and the smell baseline pasted in full, since it can read nothing this file says. Then:

> Report every place the diff breaks a standard this repo documents, citing the file and the rule, and every baseline smell you spot, naming it and quoting the hunk. A documented standard overrides the baseline. Mark each finding as a hard violation or a judgement call; a smell is always a judgement call. Skip anything the repo's tooling enforces. Return each finding with the fields `file`, `text`, `side`, `change`, `evidence`, `axis`, and `blocker`, plus `suggestion` where you have one. For `text`, give the distinctive text of the line the finding lands on, since a line number read locally is the wrong number. Stay under 600 words.

## The Spec brief

Give the sub-agent the diff command, the commit list, and the spec's contents or path. Give it the change's own claim about itself too, which is the PR description when there is one and the commit messages otherwise. Then:

> Report what the spec asked for that is missing or partial, behaviour in the diff that nobody asked for, and requirements that look implemented but implemented wrong. Report any divergence between the spec and the change's own claim about itself as a finding of its own. Quote the spec line behind each one. Return each finding with the fields `file`, `text`, `side`, `change`, `evidence`, `axis`, and `blocker`, plus `suggestion` where you have one. For `text`, give the distinctive text of the line the finding lands on, since a line number read locally is the wrong number. Stay under 600 words.
