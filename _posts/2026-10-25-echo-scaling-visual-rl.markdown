---
layout: blog-post
title: "Echo: Scaling Visual RL Without Scaling Rendering"
description: "Inverse distillation lets a cheap state-based imitator collect most of the experience, so a shared critic can train a visual policy without rendering every step."
author: "Gagan Khandate"
date: 2026-10-25 12:00:00 -0700
categories: [blog]
permalink: /blog/echo-scaling-visual-rl/
---

![Animated overview of Echo: a few rendered environments run the visual policy while many unrendered environments run a state imitator that copies it. Both streams of experience fill a shared replay buffer that trains one critic, whose action gradient directly improves the visual policy.]({{ site.baseurl }}/images/blog/echo/idea.gif)

*Render a few; simulate many. Both streams feed one critic, and the critic's gradient updates the visual policy.*

Massively parallel simulation has changed what reinforcement learning can do for robots. Thousands of environments on a single GPU, millions of transitions per minute, policies for locomotion and assembly in hours rather than days. But almost all of that speed belongs to *state-based* policies—policies that read joint angles and object poses straight out of the simulator.

The moment the policy has to look at the world through a camera, the economics change. Every environment step now needs a rendered image and a forward pass through a visual network. Physics stays cheap; seeing gets expensive, and it gets more expensive as the vision model grows.

Echo is my attempt at a simple question: **can we scale off-policy experience for visual RL without proportionally scaling rendering and visual-policy inference?**

## The usual workaround, and its cost

The common answer is two-stage teacher–student distillation. First train a privileged state-based teacher that solves the task. Then train a visual student to copy the teacher's actions.

This works surprisingly often, but it has a structural problem. The teacher can condition its behavior on information the student never sees—exact object pose, contact state, velocities hidden behind fingers. Some of the teacher's decisions are simply not reproducible from pixels. That *imitation gap* is then compounded by the usual distribution shift once the student starts making its own mistakes.

For dexterous in-hand manipulation, where the fingers routinely occlude the object, this gap is not hypothetical.

Training the visual policy directly with RL avoids the mismatch, but brings back the rendering bill. Recent work has attacked that bill in different ways: [Squint](https://arxiv.org/abs/2602.21203) renders at very low resolution, which can throw away the detail precise manipulation needs; [SDPG](https://arxiv.org/abs/2605.26478) renders only a subset of environments and estimates policy improvement from perturbed, unrendered rollouts with zeroth-order optimization. In contact-rich tasks, small perturbations can flip contact modes and produce very different returns, which is a hard regime for a sampled gradient estimator. And being on-policy, it can't reuse old experience.

Meanwhile, methods like [FastTD3](https://arxiv.org/abs/2505.22642) and FlashSAC have shown that off-policy RL pairs beautifully with massively parallel simulation: collect a lot, replay it many times, update the critic efficiently. I wanted that recipe for visual policies—without rendering every step.

## Flip the distillation

The core idea in Echo is what I call **inverse distillation**. Instead of a state-based teacher supervising a visual student, a state-based *imitator* learns to copy the evolving visual policy.

Concretely, the N parallel environments are split into two streams:

- **Rendered (M environments).** The visual policy acts from camera images. We keep the transitions and the paired (state, observation) samples.
- **Unrendered (N − M environments).** A small state-based imitator acts from privileged simulator state. No cameras, no visual network, just physics.

The imitator is trained with a simple regression: match the visual policy's noise-free action on fresh rendered states, with a stop-gradient on the visual side so imitation never pulls the visual policy toward the imitator. As the visual policy improves, the imitator keeps chasing it.

The important thing is what the imitator is *for*. It is not a teacher. It doesn't supervise anything. Its job is to be a cheap stand-in for the visual policy so that we can collect lots of experience that is approximately on the visual policy's distribution.

## One critic, two experience streams

All transitions from both streams land in a shared replay buffer and train a single privileged critic Q(s, a). That critic is what turns cheap experience into a better visual policy.

![Two key ideas in Echo: (1) a state imitator matches the visual policy's actions; (2) a shared critic trained on both replay streams provides action gradients that update the visual policy.]({{ site.baseurl }}/images/blog/echo/method.png)

*Idea 1: imitate the visual policy. Idea 2: update the visual policy through the shared critic.*

Two details make this work:

**No successor images needed.** A TD target needs an action at the next state. For unrendered transitions there is no next image, so we can't query the visual policy. Instead, an EMA copy of the imitator supplies the continuation action from the next *state*:

```
y = r + γ (1 − d) · Q_target(s', μ_target(s'))
```

That lets every transition—rendered or not—contribute to value learning.

**First-order updates of the visual policy.** The visual policy is improved by backpropagating the critic's action gradient through it, exactly like a deterministic actor-critic, using only the rendered (state, observation) pairs. So the expensive part—gradients through the visual encoder—runs on a small set of samples, while the critic that produces those gradients has seen far more experience than the visual policy ever generated.

In practice I built Echo on FastTD3: twin distributional critics, clipped double-Q, target-policy smoothing. The only additions are the imitator, its EMA target, and the split replay.

## Key results

I compared Echo against SDPG (its public implementation) on three visual locomotion tasks—Hopper, Walker, Ant—and two in-hand cube reorientation tasks with egocentric cameras—Allegro Hand and Shadow Hand—all in Genesis, three seeds each.

![Hopper, Walker and Ant learning curves: Echo, Echo without auxiliary-policy EMA, and SDPG, against wall-clock training time and against simulator transitions.]({{ site.baseurl }}/images/blog/echo/locomotion-results.png)

*Visual locomotion. Top: wall-clock time. Bottom: total simulator transitions, including Echo's auxiliary interactions. The Ant SDPG curve uses its best three runs (see the paper's appendix).*

![Allegro Hand and Shadow Hand learning curves: Echo vs SDPG, against wall-clock training time and against simulator transitions.]({{ site.baseurl }}/images/blog/echo/dexterous-results.png)

*Dexterous manipulation. Left: wall-clock time. Right: total simulator transitions, including Echo's auxiliary interactions.*

The headline numbers, relative to SDPG under the configurations I evaluated:

- **Time to reference return** drops by about 60% on average across the locomotion tasks and 56% across the two hands. On Hopper, Echo reaches SDPG's reference return in ~21 minutes versus 60. On Allegro Hand, ~96 minutes versus 180.
- **Peak mean return** improves by 62% on locomotion and 12% on the hands. Allegro ends around 700 vs. 600; Shadow Hand ends near 1100 for both, so there the win is speed, not final performance.
- **Transition efficiency.** Even counting every auxiliary step against Echo, it reaches higher mean returns at matched simulator-transition budgets on both hands.

The diagnostics were interesting too. The imitator never perfectly tracks the visual policy—imitation error stays nonzero throughout training. Yet the critic's action gradients at the visual policy's action and at the imitator's action stay well aligned: final cosine similarities between 0.55 and 0.76 across all five tasks. The imitator doesn't need to be perfect; it needs to keep the critic pointing in a useful direction.

One thing that didn't behave as cleanly as I'd like: EMA on the imitator helped on Hopper and Ant, but hurt on Walker. It's a knob, not a free win.

## What I'm careful not to claim

This is a preliminary study, and I want to be upfront about what it doesn't show.

The comparison is between complete implementations, not matched architectures or hyperparameters. The obvious missing baseline is rendered-only FastTD3—same backbone, no imitator—which would isolate how much of the gain actually comes from the auxiliary experience. Ant also comes with a baseline-selection caveat that's spelled out in the paper's appendix.

And imitation error is measured on states the visual policy visits, not on the states the imitator visits in its own rollouts. Positive gradient alignment is encouraging, but it doesn't prove the critic is accurate on auxiliary-rollout states or that the TD targets are unbiased.

## Why I'm excited about it

The deeper reason I like this direction is that it decouples two things that have been tied together: *how much experience you learn from* and *how expensive your policy is to run*.

That matters most where observations and policies are both costly:

- **Touch.** High-resolution tactile sensing, like DIGIT, is expensive to simulate and to process. Direct RL on tactile policies has the same bottleneck as vision, only worse.
- **Large models.** Vision-language-action models and world-action models are far too expensive to roll out at RL scale. If a small state-based imitator can collect most of the experience while the big model only sees a fraction, direct online RL on these architectures starts to look less absurd.
- **The imitation gap.** Because the deployed observation-based policy is optimized directly, there's no privileged teacher whose behavior it must reproduce.

None of these are tested yet. But they're the experiments I most want to run next.

## Citation

The paper will be on arXiv soon; I'll link it here when it is. In the meantime, if you find this work useful, please cite:

```bibtex
@misc{khandate2026echo,
  title  = {Echo: Scaling Visual Reinforcement Learning with Off-Policy Experience},
  author = {Khandate, Gagan},
  year   = {2026},
  note   = {arXiv preprint, forthcoming}
}
```

<!-- TODO: once on arXiv, switch to @article with journal = {arXiv preprint arXiv:XXXX.XXXXX}, add eprint/url, and link the paper in the intro. -->
