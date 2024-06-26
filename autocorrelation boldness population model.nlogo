globals
[ ; world traits
  ;;avg-habitat-temp ; set by slider, describes avg temperature of the model
  habitat-suit ; suitability metric for patches
  num-anchors
  first-anchor ;; identifications used to manipulate anchors
  second-anchor
  third-anchor
  fourth-anchor
  moisture-boundary-neg ;; lower value boundary after which moisture values are pulled back towards zero.
                   ;; intended to normalize values and limit extremity.
  moisture-boundary-pos ;; upper value boundary after which moisture values are pulled back towards zero.
                   ;; intended to normalize values and limit extremity.
  dist-moved
  num-dead
  num-spawned
  tick-count
  living-frogs
  time-since-rain ;; tracker for rain delay
  moisture-gain-threshold ;; moisture of patch above which frogs gain moisture
  ;;wetness-threshhold is wetness of frog, below which they decide to move. set by user in interface.
  ;;percent-correct
]
undirected-link-breed [ dists dist ]
patches-own
[
  patch-moisture ; patch-owned moisture value. individual to each patch.
  is_anchor ; boolean used to create agentset of current anchor patches
]

turtles-own ;; salamander traits
[
  start-patch
  patch-last ; used to save patch for movement distance calculation
  wetness ; low wetness will impact movement choices
  calcdensity ; density value of turtles calculated by procedure calculate-density
]

to anchorsetup ; setup function for habitats clustered around anchor patches
  clear-all
  set tick-count 0
  set moisture-gain-threshold 0 ; set moisture gain threshhold.
  ask patches [
    set is_anchor false ;; no patches have been chosen as anchors yet
    set moisture-boundary-pos 100 ;; moisture value boundaries after which patches are normalized towards 0
    set moisture-boundary-neg -100
    set patch-moisture random-normal 0 5 ;; creates base values for background (non-habitat) patches
    color-by-quality]

  set first-anchor one-of patches ; // assigns random patch to be anchor
  ask first-anchor [ set is_anchor true ] ;; patch is anchor

  set second-anchor one-of patches with [ is_anchor = false] ; ;; ensures it doesnt choose a patch thats already an anchor
  ask second-anchor [ set is_anchor true]

  set third-anchor one-of patches with [ is_anchor = false];
  ask third-anchor [ set is_anchor true]

  set fourth-anchor one-of patches with [ is_anchor = false];
  ask fourth-anchor [ set is_anchor true]

  ask first-anchor [set patch-moisture random-normal 50 50 ; anchor patch is assigned a value from 0 to 100 (plus tails)
  color-by-quality]
  ask second-anchor [set patch-moisture random-normal 50 50 ;
  color-by-quality]
  ask third-anchor [set patch-moisture random-normal 50 50 ;
  color-by-quality]
  ask fourth-anchor [set patch-moisture random-normal 50 50 ;
  color-by-quality]

  ask first-anchor
  [make-anchor-habitat] ;; generates "habitat" - a random [n] of patches in the radius (set by slider habitat-size) of the anchor patch

  ask second-anchor
  [make-anchor-habitat]

  ask third-anchor
  [make-anchor-habitat]

  ask fourth-anchor
  [make-anchor-habitat]

  set-default-shape turtles "frog top"
  set num-spawned 100
  create-turtles 100
  [
    set color white
    set size 1.5
    setxy (random-xcor) (random-ycor) ; turtles are placed randomly
    set wetness 100 ; wetness starts at 100
  ]
  reset-ticks;
end

to anchor-go
if ticks > 0 and ticks mod 1 = 0
  [
    if num-dead = num-spawned
       [
          ;;beep
          stop
       ] ; when all turtles die, the model stops.
    ask turtles [wetness-boundary-checking] ; turtles check wetness: if value is outside boundaries, it is normalized by procedure wetness-boundary-check
  ask patches
    [
      set patch-moisture ((patch-moisture + ((1.0 - NOISE) * (random-normal -5 20))) + ([patch-moisture] of one-of neighbors)) / 2 ; temporal autocorrelation: NOISE is a decimal variable for how strongly current patch moisture influences the new moisture value. 1.0 - NOISE is then the strenth of the random effect that is added to vary patches. Moisture is then averaged with a neighbor patch to give spatial correlation.
      moisture-boundary-check
    ]

  ask first-anchor [set patch-moisture (patch-moisture + ((1.0 - NOISE) * (random-normal 0 10)))] ; // makes quality of anchor vary a little - adds a number between 0 and 5 to the quality value
  ask first-anchor
    [
      anchor-habitat-vary
    ]


  ask second-anchor [set patch-moisture (patch-moisture + ((1.0 - NOISE) * (random-normal 0 10)))] ;; same as for first-anchor
  ask second-anchor
    [
      anchor-habitat-vary
    ]


  ask third-anchor [set patch-moisture (patch-moisture + ((1.0 - NOISE) * (random-normal 0 10)))] ;
  ask third-anchor
    [
      anchor-habitat-vary
    ]


  ask fourth-anchor [set patch-moisture (patch-moisture + ((1.0 - NOISE) * (random-normal 0 10)))] ;
  ask fourth-anchor
    [
      anchor-habitat-vary
    ]
    ask patches
    [
      color-by-quality
    ]
  ]

  ask patches [fade-anchor] ;; if habitat patch-quality average less than -5 [number not from data] AND generated float < prob-change, patch fades
  ;ask patches [fade-anchor-new]
  ask patches [rain]
  ask patches [moisture-boundary-check]
  ask patches [color-by-quality]

  ask turtles [move] ;;
  ask turtles [desiccate]
  ask turtles [
    create-dists-with other turtles ; these links are used to calculate density- see procedure calculate-density
    ask my-links [hide-link]
  ]
  ask turtles [calculate-density]
  ask turtles [wetness-boundary-checking] ; normalize turtle wetness Again
  if density-damage [ask turtles [density-effect]] ;;
  ask turtles [death]
  set tick-count (tick-count + 1)
  set time-since-rain (time-since-rain + 1)
  tick;
  if ticks = 100
     [
       ;beep
       stop
     ]
  set living-frogs count turtles
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; functions

to anchor-habitat-vary ; anchor habitat patches have more stable moisture than average patches: it varies less per tick.
  if habitat-size = 2 ;
  [
    ask up-to-n-of 13 patches in-radius 2 ;
    [set patch-moisture (patch-moisture + random-normal 0 5) ; variation is addition of a value between -5 and 5 (plus tails)
    color-by-quality]
  ]
  if habitat-size = 3 ;
  [
    ask up-to-n-of 25 patches in-radius 3 ;
    [set patch-moisture (patch-moisture + random-normal 0 5) ;
    color-by-quality]
  ]
  if habitat-size = 4 ;
  [
    ask up-to-n-of 37 patches in-radius 4 ;
    [set patch-moisture (patch-moisture + random-normal 0 5) ;
    color-by-quality]
  ]
  if habitat-size = 5 ;
  [
    ask up-to-n-of 49 patches in-radius 5 ;
    [set patch-moisture (patch-moisture + random-normal 0 5) ;
    color-by-quality]
  ]
  if habitat-size = 6 ;
  [
    ask up-to-n-of 62 patches in-radius 6 ;
    [set patch-moisture (patch-moisture + random-normal 0 5) ;
    color-by-quality]
    ; back save: set patch-moisture patch-moisture + random-normal 5 15
  ]
end

to calculate-density ; density is mean distance between turtles- each turtle creates a link to every other turtle and averages the link length
  if living-frogs > 1
  [
     set calcdensity mean [link-length] of dists
  ]
end

to color-by-quality
  set pcolor (scale-color green patch-moisture 200 -200) ;; higher quality means darker color
end

to density-effect
  if calcdensity < 15 ;; turtles "steal" moisture from each other
  [
    ;print "density damage occurring"
    set wetness (wetness - 10) ;; density wetness effect
    rt random-normal 0 180
    fd 10 ;; move forward in random direction to break up clumping
    set wetness (wetness - 20)
  ]
end

to desiccate
  if [patch-moisture] of patch-here < moisture-gain-threshold
  [set wetness (wetness - 20)] ;; if the new patch has low quality, moisture is lost (movement is more taxing in drier/low quality patches)
  if [patch-moisture] of patch-here >= moisture-gain-threshold
  [set wetness (wetness + 5)]
end

to death
  if wetness <= 0 ;; when turtle wetness reaches zero, it dies.
  [
    set num-dead (num-dead + 1)
    die
  ]
end

to fade-anchor
  let fade-threshold 0
    if ticks > 0 and ticks mod 1 = 0
  [
    ask first-anchor ;; if habitat average moisture less than fade-threshold AND generated float < prob-change, patch fades
     [
      if mean [patch-moisture] of patches in-radius habitat-size < fade-threshold
      [
        if random-float 1 < prob-change-1
        [
          ask first-anchor
          [
              set is_anchor false
            ask patches in-radius habitat-size
            [
              set patch-moisture random-normal 0 5 ;; sets patches of habitat back to standard background variation
            ]
            set first-anchor one-of patches with [ is_anchor = false];; anchor moves.
            make-anchor-habitat
              ask first-anchor                        ;; this block is an attempt to get newly-moved patches to persist instead of fading again so quickly
              [                                       ;;
                ask patches in-radius habitat-size    ;;
                [set patch-moisture patch-moisture + 20] ;;
              ]                                       ;;
            ;print "first-anchor moved!"
          ]
        ]
      ]
    ]
    ask second-anchor ;; if habitat average moisture less than fade-threshold AND generated float < prob-change, patch fades
     [
      if mean [patch-moisture] of patches in-radius habitat-size < fade-threshold
      [
        if random-float 1 < prob-change-2
        [
          ask second-anchor
          [
              set is_anchor false
            ask patches in-radius habitat-size
            [
              set patch-moisture random-normal 0 5
            ]
            set second-anchor one-of patches with [ is_anchor = false]
            make-anchor-habitat
              ask second-anchor
              [
                ask patches in-radius habitat-size
                [set patch-moisture patch-moisture + 20]
              ]
            ;print "second-anchor moved!"
          ]
        ]
      ]
    ]
    ask third-anchor ;; if habitat average moisture less than fade-threshold AND generated float < prob-change, patch fades
     [
      if mean [patch-moisture] of patches in-radius habitat-size < fade-threshold
      [
        if random-float 1 < prob-change-3
        [
          ask third-anchor
          [
            set is_anchor false
            ask patches in-radius habitat-size
            [
              set patch-moisture random-normal 0 5
            ]
            set third-anchor one-of patches with [ is_anchor = false]
            make-anchor-habitat
              ask third-anchor
              [
                ask patches in-radius habitat-size
                [set patch-moisture patch-moisture + 20]
              ]
            ;print "third-anchor moved!"
          ]
        ]
      ]
    ]
    ask fourth-anchor ;; if habitat average moisture less than fade-threshold AND generated float < prob-change, patch fades
    [
      if mean [patch-moisture] of patches in-radius habitat-size < fade-threshold
      [
        if random-float 1 < prob-change-4
        [
          ask fourth-anchor
          [
            set is_anchor false
            ask patches in-radius habitat-size
            [
              set patch-moisture random-normal 0 5
            ]
            set fourth-anchor one-of patches with [ is_anchor = false]
            make-anchor-habitat
            ask fourth-anchor
              [
                ask patches in-radius habitat-size
                [set patch-moisture patch-moisture + 20]
              ]
            ;print "fourth-anchor moved!"
          ]
        ]
      ]
    ]
  ]
end

to make-anchor-habitat
  if habitat-size = 2 ;
  [
    ask up-to-n-of 13 patches in-radius 2 ;
    [set patch-moisture patch-moisture + random-normal 50 25 ; patches within radius add val between 25 and 75 (plus tails) to moisture
    color-by-quality]
  ]
  if habitat-size = 3 ;
  [
    ask up-to-n-of 25 patches in-radius 3 ;
    [set patch-moisture patch-moisture + random-normal 50 25 ;
    color-by-quality]
  ]
  if habitat-size = 4 ;
  [
    ask patches in-radius 4 ;
    [set patch-moisture patch-moisture + random-normal 50 25 ;
    color-by-quality]
  ]
  if habitat-size = 5 ;
  [
    ask patches in-radius 5 ;
    [set patch-moisture patch-moisture + random-normal 50 25 ;
    color-by-quality]
  ]
  if habitat-size = 6 ;
  [
    ask patches in-radius 6 ;
    [set patch-moisture patch-moisture + random-normal 50 25 ;
    color-by-quality]
  ]
end

to moisture-boundary-check ;;
  if patch-moisture >= 100 ;
          [
            set patch-moisture 100
            set patch-moisture patch-moisture - random-normal 20 10 ; normalizes by subtracting val 10-30 (plus tails)
          ]
      if patch-moisture <= -100 ;
          [
            set patch-moisture -100
            set patch-moisture patch-moisture + random-normal 20 10 ; normalizes by adding val 10-30 (plus tails)
          ]
end

to move-penalty
  let patch-current patch-here
  ask patch-last
       [
         set dist-moved distance patch-current
       ]
  set wetness wetness - (dist-moved)
  ;print "movement penalized."
end
to move-wet
  let chance-correct (random 100) ; turtles have a chance of making the "correct" choice (moving to highest moisture patch in range)
  let percent-correct ((100 - wetness-threshold) - random-normal 0 10)
  if chance-correct <= percent-correct
  [
    set patch-last patch-here ; saving patch turtle is on before movement
    let p max-one-of other patches in-radius 2 [patch-moisture] ;; chooses neighboring patch with highest quality
    if [patch-moisture] of p >= [patch-moisture] of patch-here [move-to p] ;;move to highest moisture patch of neighbors UNLESS current patch is highest.
    if [patch-moisture] of p < [patch-moisture] of patch-here ; if max moisture of neighbors is less than current patch, turtle doesnt move.
    []
  ]
  if chance-correct >= percent-correct ;; was originally 60 for some reason? why was it hard coded
  [
    rt random-normal 0 180
      fd 5 ;; move forward in random direction. (distance halved)
      ;;set wetness (wetness - 20) this was an extra penalty to bad decision making. unfair?
  ]
end

to move ;; if wetness of the patch is not enough to gain moisture, AND if turtle is drier than wetness threshhold for movement, MOVE-WET.
  set patch-last patch-here ; saving patch before turtle moves.
  if [patch-moisture] of patch-here <= moisture-gain-threshold
  [
    if wetness <= wetness-threshold [move-wet]
  ]
  move-penalty
end

to rain
  if time-since-rain >= 20
  [
    if random 100 <= prob-rain ; rain has a CHANCE to occur only every 20 ticks
    [
      ask n-of 2 patches with [is_anchor = false]; ;; when rain happens, two random patches are chosen to have quality increased.
      [
        set patch-moisture (patch-moisture + 40)
        ask n-of 10 patches in-radius 3
        [ set patch-moisture (patch-moisture + 30) ] ;; spread of patches around the chosen rain patches receive rain, but less
      ]
      ;print "rainfall"
      set time-since-rain 0
    ]
  ]
end

to wetness-boundary-checking
  if wetness >= 100
  [
    set wetness 100
    set wetness wetness - random-normal 25 10 ; value between 15 and 35 is subtracted from wetness
    ;print wetness
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
453
10
831
389
-1
-1
11.212121212121213
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
ticks
30.0

SLIDER
120
299
231
332
habitat-size
habitat-size
2
6
5.0
1
1
NIL
HORIZONTAL

SLIDER
6
212
133
245
wetness-threshold
wetness-threshold
0
100
71.0
1
1
NIL
HORIZONTAL

SLIDER
7
298
114
331
prob-rain
prob-rain
0
100
80.0
5
1
NIL
HORIZONTAL

SLIDER
6
338
115
371
prob-change-1
prob-change-1
0
1
0.5
.1
1
NIL
HORIZONTAL

SLIDER
120
338
231
371
prob-change-2
prob-change-2
0
1
0.5
.1
1
NIL
HORIZONTAL

SLIDER
6
377
114
410
prob-change-3
prob-change-3
0
1
0.5
.1
1
NIL
HORIZONTAL

SLIDER
121
377
231
410
prob-change-4
prob-change-4
0
1
0.5
.1
1
NIL
HORIZONTAL

BUTTON
21
14
109
47
anchor setup
anchorsetup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
21
51
109
84
anchor go
anchor-go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
21
89
109
122
anchor step
anchor-go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
7
449
91
482
show anchor 1
ask first-anchor [set pcolor red]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
7
487
92
520
show anchor 2
ask second-anchor [set pcolor orange]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
103
449
185
482
show anchor 3
ask third-anchor [set pcolor yellow]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
103
488
184
521
show anchor 4
ask fourth-anchor [set pcolor lime]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
190
469
276
502
recolor anchors
ask first-anchor [color-by-quality] \nask second-anchor [color-by-quality] \nask third-anchor [color-by-quality]\nask fourth-anchor [color-by-quality]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
140
63
229
108
mean wetness
mean [wetness] of turtles
2
1
11

MONITOR
139
10
229
55
living-frogs
living-frogs
17
1
11

SWITCH
7
173
133
206
density-damage
density-damage
0
1
-1000

PLOT
257
187
438
336
average patch-moisture
NIL
NIL
0.0
1000.0
-100.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "ask patches [plot mean [patch-moisture] of patches]"

PLOT
239
10
439
160
living frogs
NIL
NIL
0.0
100.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

MONITOR
318
347
438
392
mean patch-moisture
mean [patch-moisture] of patches
2
1
11

MONITOR
140
117
229
162
mean density
mean [calcdensity] of turtles
2
1
11

SLIDER
7
257
114
290
NOISE
NOISE
0
1.0
0.25
.05
1
NIL
HORIZONTAL

@#$#@#$#@
## Purpose 
The purpose of the IBM was to evaluate the success of varyingly bold behavioral strategies at different levels of environmental temporal autocorrelation.
State variables and scales. The IBM consisted of autonomous frog agents spawned on a grid of patches. Frogs were characterized by user-set wetness-threshold, last saved location, and current location. Patches were characterized by moisture and anchor status. The model consisted of a 16 by 16 grid of patches. Within the grid, four randomly placed habitats (clumps of patches with more stable moisture) were generated around a central habitat anchor patch. The passage of time was represented by the number of ticks, and each model trial lasted 100 ticks.
Process overview and scheduling. In the setup procedure, all patches were given a randomly-generated moisture value. 100 frogs with an internal wetness of 100 were spawned at random patches. In the main procedure at each tick, the following procedures happened in sequence. The moisture of all patches was varied, with the strength of variation related to user-set autocorrelation. Within a habitat clump, moisture varied less strongly, but was again related to user-set autocorrelation. Rain had a chance to occur randomly across the model grid to replenish lost moisture in patches. Each frog ran the move procedure, and frogs then desiccated in proportion with amount of movement. Population density was evaluated, and a density penalty to wetness occurred. At the end of each tick, frogs died if internal wetness had reached 0.

## Design concepts
Emergence. 
- All patterns of movement and survival emerged as a result of movement of individuals, and of population density related detrimental effects.
Adaptation.
- The frog movement decision process within the move procedure is directly objective-seeking, functioning as follows. If the occupied patch was below the threshold at which frog occupants gain moisture, the frog then evaluated internal wetness. If the internal wetness was below the user-set wetness-threshold value, the move-wet procedure was triggered, wherein the frog moves to the highest moisture patch within a radius of 2.
Stochasticity. 
- Stochastic events included variation of patch moisture, rainfall, and directed movement success. When patch moisture was varied at each tick, the following equation was used. New moisture = current-moisture + (autocorrelation percent * random value in specified range with Gaussian distribution). For background (non-habitat, non-anchor) patches, the range for the random value was -15 to 15 plus tails. The output of this equation was then averaged with the current-moisture of a randomly chosen neighbor. For anchor patches, the range was instead -10 to 10, and no averaging occured. Within a habitat, patches simply had a random value between -5 and 5, Gaussian dist., added to their moisture value.
- Rainfall had a chance to occur every 20 ticks. A random number between 0 and 100 was generated, and if that number was greater than the user-set probability of rain (prob-rain), two random non-anchor patches were chosen to receive rain. Each chosen patch had 40 moisture added to its patch-moisture. 10 random patches in a radius of 3 received a smaller addition of 30 moisture. 
- Directed movement (the move-wet procedure) had a stochastic probability of occurring as opposed to random movement. The likelihood of a frog moving correctly was related to boldness and was calculated as follows. Percent-correct = (100 - wetness-threshold - random value in range -10 to 10, Gaussian dist.) For each frog running move-wet, a random number between 0 and 100 was generated. If that number was above the calculated percent-correct, the frog moved to the highest moisture patch in a radius of 2.
Collectives.
- Frogs tended to aggregate in clumps in patch areas with higher moisture.
Observation. 
- By altering boldness and autocorrelation, the user can investigate how these parameters impact anuran survival. The model can be additionally customized as needed by modifying the probability of rain (prob-rain), the size of habitat clumps (habitat-size), and the probability of each anchor patch fading and reappearing elsewhere (prob-change-1:4).
## Submodels.
Setup.
- On initiation, all patches were given a moisture value generated on a random-normal (Gaussian) distribution between 0 and 5. Four patches were randomly chosen to be habitat anchors. Each anchor patch and a number of patches within the user-set "habitat-size" radius were given a moisture value generated on a random-normal (Gaussian) distribution between 0 and 100 and colored according to their moisture, with darker blues indicating higher moisture.

## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)


## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)


a HABITAT is defined as a group of patches clumped together within a radius. That radius is set by the user with the HABITAT-SIZE slider.

The PROB-CHANGE slider controls the probability that a habitat will move location vs persist.

The PROB-RAIN slider controls the probability that rain will fall at each interval of 5 ticks.


## THINGS TO NOTICE

(suggested things for the user to notice while running the model)


## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

frog top
true
0
Polygon -7500403 true true 146 18 135 30 119 42 105 90 90 150 105 195 135 225 165 225 195 195 210 150 195 90 180 41 165 30 155 18
Polygon -7500403 true true 91 176 67 148 70 121 66 119 61 133 59 111 53 111 52 131 47 115 42 120 46 146 55 187 80 237 106 269 116 268 114 214 131 222
Polygon -7500403 true true 185 62 234 84 223 51 226 48 234 61 235 38 240 38 243 60 252 46 255 49 244 95 188 92
Polygon -7500403 true true 115 62 66 84 77 51 74 48 66 61 65 38 60 38 57 60 48 46 45 49 56 95 112 92
Polygon -7500403 true true 200 186 233 148 230 121 234 119 239 133 241 111 247 111 248 131 253 115 258 120 254 146 245 187 220 237 194 269 184 268 186 214 169 222
Circle -16777216 true false 157 38 18
Circle -16777216 true false 125 38 18

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

salamander
true
0
Polygon -7500403 true true 145 15 157 15 169 30 170 44 171 57 166 69 138 65 136 59 134 45 134 32 135 31
Polygon -7500403 true true 165 65 160 128 171 169 191 229 192 265 176 285 142 293 90 275 96 273 150 281 172 257 166 224 149 201 132 181 123 157 124 126 133 90 139 63
Polygon -7500403 true true 142 85 124 79 119 86 140 97
Polygon -7500403 true true 159 96 179 89 175 83 156 86
Polygon -7500403 true true 169 87 190 69 194 73 176 91
Polygon -7500403 true true 127 83 121 63 115 66 119 87
Polygon -7500403 true true 118 67 110 63 113 59 115 64 113 50 118 52 118 61 122 54 124 57 120 65
Polygon -7500403 true true 188 72 184 64 188 62 189 68 191 56 194 59 193 68 197 67 202 70 191 73
Polygon -7500403 true true 142 187 120 187 121 193 150 201
Polygon -7500403 true true 169 180 177 161 185 163 179 192
Polygon -7500403 true true 177 162 195 159 198 165 182 168
Polygon -7500403 true true 124 187 112 190 116 194 125 192
Polygon -7500403 true true 116 193 106 199 105 195 110 194 101 190 102 185 110 191 108 184 114 185 114 191
Polygon -7500403 true true 193 158 199 153 203 157 194 159 208 159 210 162 199 163 206 169 202 169

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="frog data" repetitions="200" runMetricsEveryStep="false">
    <setup>anchorsetup</setup>
    <go>anchor-go</go>
    <timeLimit steps="100"/>
    <exitCondition>not any? turtles</exitCondition>
    <metric>living-frogs</metric>
    <enumeratedValueSet variable="prob-change-4">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-change-1">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="density-damage">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-rain">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NOISE">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wetness-threshold">
      <value value="37"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="old-percent-correct">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-change-2">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-change-3">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-size">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
