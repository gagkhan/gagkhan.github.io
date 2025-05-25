---
layout: post
title:  "Safe RL for Islands & Bridges: A Topologically Isomorphoic Problem to In-hand Manipulation"
date:  2019-12-15 22:21:59 +00:00
image: regular_maze.png
categories: other
author: "Gagan Khandate"
authors: "Maximillian Haas-Heger, <strong>Gagan Khandate</strong>, Matei Ciocarlie"

# slides: /pdfs/jcdl2019.pdf
# code: https://github.com/leonidk/venue_scores
---
Dexterous in-hand manipulation can be thought of traversing narrow regions of stable state space while moving between relatively more stable grasp poses.  Mimicing this structure, we construct a topologically isomorphic problem, islands and bridges, wherein we connect large islands by narrow bridges to correspond to stable and unstable state-space respectively. Here, we demonstrate that using a shield to ensure safe actions signficantly improves sample complexity for goal based navigation. Our results suggest safe reinforcement learning for enabling model free learning for in-hand manipulation.