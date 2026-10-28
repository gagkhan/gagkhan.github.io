---
layout: blog-post
title: "What SuperMimic Makes Me Excited About: Sim-to-Real Dexterity"
author: "Gagan Khandate"
date: 2026-10-28 14:48:00 -0700
description: "Thoughts on learned dynamics, object representations, and adapting dexterous manipulation policies to real-world data."
categories: blog
permalink: /blog/lessons-from-supermimic/
---

[SuperMimic](https://arxiv.org/abs/2610.28480) makes me more optimistic about model-based RL for dexterous manipulation. The single-GPU training result is impressive, but I am more interested in what an efficient, differentiable world model could let us do after simulation pretraining: adapt the dynamics to real data, then improve the policy through the adapted model.

The appealing possibility is that real interaction could improve a model we reuse across skills. If that works, the cost of adaptation could be amortized across a growing repertoire. For multi-fingered manipulation, that is the opportunity I would most like to pursue.

## 1. Learning dynamics and object representation

> The right representation balances cheap dynamics rollouts with effective learning from real-world data.

SuperMimic fits a world model to simulator transitions and trains a tracking policy through short imagined rollouts. The authors report surpassing the released SONIC checkpoint’s return in three hours on one H100, with different hardware and data budgets between the two systems. It is a motion-tracking result, but it makes the computational case for policy learning through learned dynamics much more compelling. ([Results and accounting](https://supermimic.github.io/))

The cost of a learned dynamics rollout can vary dramatically with how we represent objects and their interactions.

The choice affects where we spend compute, what supervision real-data adaptation requires, and which rewards we can reuse. It also determines how much of the model can carry over to new objects and environments.

![The same object visualized as SE(3), keypoints, a point cloud, and RGB/depth observations.]({{ site.baseurl }}/images/blog/supermimic/object-representations.svg)

| Representation | Dynamics and compute | Real-data adaptation | Reward and transfer implications |
| --- | --- | --- | --- |
| **SE(3)** | Compact rollouts; geometry and physical properties need separate conditioning. | Requires pose estimates, consistent frames, and motion history or velocities. | Convenient pose rewards; cross-object reuse depends on geometry conditioning and reliable estimation. |
| **Keypoints** | Small prediction targets; point selection limits the interactions the model can capture. | Requires stable correspondences under occlusion and across domains. | Supports relational rewards; transfer depends on consistent point meaning and contact coverage. |
| **Point clouds** | Geometry-aware modeling; cost depends on point count, sampling, and architecture. | Must handle partial views, coordinate frames, and changing point sets. | Supports geometric objectives; scene coverage helps reuse, but missing contact surfaces remain a limitation. |
| **RGB / depth** | Encoder and prediction costs can be substantial; compact latent rollouts can reduce repeated computation. | Can train against sensor observations, while handling appearance shifts, depth artifacts, and calibration. | Enables visual or latent rewards and pretrained features; reward semantics must survive domain and representation changes. |

A cheap transition model can still leave us with an expensive perception and supervision pipeline. Conversely, richer observations need not imply dense prediction at every imagined step. [Keypoints into the Future](https://proceedings.mlr.press/v155/manuelli21a.html) demonstrates manipulation with learned keypoint dynamics, while [Dreamer](https://openreview.net/pdf?id=S1lOTC4tDS) learns behavior through compact latent rollouts. The relevant cost is the complete path from real observations to differentiable policy updates.

I would make this choice with adaptation and reward design in mind from the start. If fitting the model requires quantities that are difficult to estimate on hardware, that constrains the real data we can use. If the reward depends on those same quantities, it inherits that constraint. And if the representation leaves out relevant object or environment interactions, adapting the dynamics may not be enough to recover them. These are the downstream consequences that matter more to me than the representation in isolation.

## 2. Adapting the dynamics with real-world data

One useful comparison is [RMA](https://www.roboticsproceedings.org/rss17/p011.html): recent interaction history is used to infer a latent context that conditions a trained policy. The behavior adapts online, while the policy weights remain fixed at deployment.

An efficient learned world model makes a different route worth revisiting: **adapt the dynamics to real data, then reoptimize the policy through the adapted model.** The correction lives in the predictive model, with the possibility of reusing it across policies and tasks. This brings model fitting and policy optimization into the adaptation loop, so its computational cost matters; it is a different timescale from RMA’s rapid contextual adaptation.

With the representation chosen, the question is how much useful dynamics correction we can obtain from a small real-data budget, and how broadly that correction applies.

![Proposed adaptation architecture: real transitions fit the world model; imagined rollouts train the policy through a fixed reward interface. The reuse test is whether skill A data improves skill B.]({{ site.baseurl }}/images/blog/supermimic/adaptation-architecture.svg)

*Solid arrows show the data and deployment paths; the dashed arrow shows the policy-gradient path. The world model is adapted between policy-optimization phases.*

For example, could model adaptation from one in-hand manipulation skill improve another skill involving the same hand and object? That would be a stronger result than recovering the performance of the policy used to collect the adaptation data. It would suggest we had learned something reusable about the interaction.

There are relevant precedents. [PDDM](https://proceedings.mlr.press/v100/nagabandi20a.html) demonstrated learned-dynamics MPC on a real 24-DoF hand using four hours of real-world data. [DayDreamer](https://proceedings.mlr.press/v205/wu23c.html) demonstrated world-model learning directly on physical robots, including manipulation. [DiffTactile](https://proceedings.iclr.cc/paper_files/paper/2024/hash/1cc70be9fb6a83bc46cf4ac21a91e0b0-Abstract-Conference.html) used real data to refine physical parameters in differentiable simulation. Together, these motivate the direction; the particular combination of simulation pretraining, rapid neural-model adaptation, and policy improvement for multi-fingered manipulation remains the hypothesis here.

### 2.a. Can we leave the reward model alone?

A well-designed reward model could make this approach considerably more attractive. Ideally, we would adapt the dynamics using real transitions while keeping the reward model fixed—without requiring real reward labels or explicit real-world state reconstruction for reward evaluation.

That makes reward design part of the transfer architecture. A reward defined over transferable observations or a stable shared representation could potentially be reused after dynamics adaptation. This is one of the ideas I am most interested in testing.

The dependency is representation stability. Freezing a reward head is not enough if model adaptation changes the meaning of its inputs. We need an interface that preserves reward semantics while allowing the dynamics to change. Dreamer’s separate dynamics and reward predictions provide relevant architectural context, although they do not establish this transfer property. ([Hafner et al.](https://openreview.net/pdf?id=S1lOTC4tDS))

For analytical policy gradients, the reward must also provide useful derivatives along imagined trajectories. Avoiding explicit state estimation for reward computation does not remove state inference from the rest of the system. But it could remove a substantial dependency from the real-data adaptation process.

## Conclusion

To me, SuperMimic has reinvigorated the discussion around model-based RL. It makes efficient policy learning through learned dynamics feel like a direction worth revisiting for dexterous manipulation. What excites me most is the possibility of adapting those dynamics to real experience and reusing that adaptation across skills.

The representation and reward choices will matter a great deal. We need dynamics that are cheap to roll out but can still learn the relevant corrections from real data. If the reward can transfer without its own fine-tuning or state-estimation pipeline, the approach becomes even more appealing. There is plenty left to figure out, but this feels like a promising time to work on it.
