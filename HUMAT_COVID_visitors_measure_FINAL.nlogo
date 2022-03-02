; this is a version of HUMAT which works for observable behaviours; for unobservable behaviours the knowledge about alters in the social networks will have to be represented differently, and this has an impact on dissonance reduction strategies (how do you calculate social satisfaction?, how do you choose who to get information from? and how do you choose who to try to convince?)
; This model investigates the interaction between support base for the COVID visitors measure and the need to experience social contact. It is a part for the Masters Project of Oscar de Vries for Artificial Intelligence, Rijksuniversiteit Groningen.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;           IMPORTS           ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extensions [
  csv
  matrix
  table]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; GLOBALS AND BREED VARIABLES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

globals [
  opinion_check
  day
  hour
  mean_hours
  mean_difference_in_hours
  behavioural-alternatives
  percentage_in_dilemma
]
breed [HUMATS HUMAT]


HUMATS-own [
  opinion_measure
  opinion_difference_this_day
  n_contacts_this_day
  hours_of_contact_this_day
  desired_n_contacts_this_day
  desired_hours_of_contact_this_day
  difference_hours

  stubbornness

  in_dilemma?
  #dilemmas

  behaviour
  ;  exp_satisfaction_per_contact_weight    ; depending on the number of contacts each agent has, a weight is determined for altering experiental satisfaction (more initial contacts -> fewer satisfation per active contact)

  ses ;socio-economic status ; for now random < 0 ; 1 >
  ;;;dissonance-related variables;;;

  ;variables calculated for all BAs;
  experiential-importance
  social-importance
  values-importance

  experiential-satisfaction-contact
  social-satisfaction-contact
  values-satisfaction-contact


  experiential-satisfaction-no-contact
  social-satisfaction-no-contact
  values-satisfaction-no-contact

  extra_exp_contact
  opinion_values_influence

  experiential-evaluation-contact ; evaluation of contact (behavioural alternative i) with respect to experiential group of needs for HUMAT j <-1;1>
  social-evaluation-contact ; evaluation of contact (behavioural alternative i) with respect to social group of needs for HUMAT j <-1;1>
  values-evaluation-contact ; evaluation of contact (behavioural alternative i) with respect to values for HUMAT j <-1;1>

  experiential-evaluation-no-contact ; evaluation of no-contact (behavioural alternative ~i) with respect to experiential group of needs for HUMAT j <-1;1>
  social-evaluation-no-contact ; evaluation of no-contact (behavioural alternative ~i) with respect to social group of needs for HUMAT j <-1;1>
  values-evaluation-no-contact ; evaluation of no-contact (behavioural alternative ~i) with respect to values for HUMAT j <-1;1>

  evaluations-list-contact
  evaluations-list-no-contact

  satisfaction-contact
  satisfaction-no-contact

]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; SETUP & GO  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  make-HUMATS
  set-social-networks-limited
  set-opinions
  set-needs-and-satisfactions

  determine-color
  set day 0
  set hour 0
  reset-ticks
  update-plots
end


to go
  ; Update time and apply day changes
  set hour ticks mod 24

  ; Day changes and choose behavior:
  if ticks mod 24 = 0 [
    if ticks > 0 [ ; prevents incrementing day and applying changes at first tick
      set day day + 1
      ask humats [set difference_hours hours_of_contact_this_day - desired_hours_of_contact_this_day]
      set mean_hours mean [hours_of_contact_this_day] of HUMATS
      apply-day-changes  ; changes are applied after every 24 hours, opinions and satisfaction levels are adjusted
    ]
    determine-color
    determine-desired-hours
    evaluate-and-choose-behavior
    check-dilemmas
  ]

  ; Act:
  humat-inquires
  stop-active-contact
  make-contact
  contact-opinion-influence

  count-active-connections
  if stop-condition [stop]
  tick
end

to-report stop-condition
  if stop-at-day-hundred? and day = 100 [report TRUE]
  report FALSE
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;       MAIN PROCEDURES      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to contact-opinion-influence
  ; Social influence happens between HUMATs in active contact (either directly on indirectly through another friend), for each tick they slighly influence each other.

  ask HUMATS [
    ; First, determine who the HUMAT has contact with:
    ; count first order connections (directly connected to HUMAT)
    let first_order_connections link-neighbors with [[color = green] of link-with myself]

    ; Only execute the remainder if HUMAT has at least one active connection
    if count first_order_connections > 0 [  ; Find higher order contacts from: loop and add connections of connections until no more HUMATs are added
      let sum_connections first_order_connections
      let done FALSE

      ; Determine cluster of active connections: who is directly or indirectly in contact with this HUMAT
      while [not done] [   ; iteratively add HUMATs to active agentsets
        let #connections count sum_connections
        foreach sort sum_connections [the-turtle ->
          ask the-turtle [
            ask my-links with [color = green] [
              set sum_connections  (turtle-set sum_connections other-end)   ; adds active connections to the agentset
            ]
          ]
        ]
        if #connections = count sum_connections [set done TRUE]  ; no new HUMATs added this iteration -> loop can be stopped
      ]

      ; Second, determine the influence:
      let my-opinion opinion_measure                          ; store HUMATs opinion in temporary variable
      let diff 0
      ask sum_connections   ; update opinion according to cluster of contact
      [
        let other-opinion opinion_measure     ; determine opinion of the other agent. Note that the agentset 'sum_connections' also includes HUMAT itself, but since its opinion is equal to itself, this will not have any influence.

        if abs(other-opinion - my-opinion) > min_attraction_dif  and abs(other-opinion - my-opinion) <= max_attraction_dif   ; only update when difference between opinions is on a certain interval
        [ set diff diff + ((other-opinion - my-opinion) * social-influence-per-tick) ] ; adjust humat's opinion towards the other, with a percentage of the difference

        if repulsion? and abs(other-opinion - my-opinion) > repulsion_dif
        [ set diff diff + ((my-opinion - other-opinion) * social-influence-per-tick) ] ; adjust humat's opinion away from the other, with a percentage of the difference
      ]
       set opinion_difference_this_day opinion_difference_this_day + diff
    ]
  ]
end



to make-contact
; In this function HUMATS attempt to make contact with friends in their network. The alter has to accept this contact in order to create an active connection.

  ask HUMATS with [
    behaviour = "contact" or                       ; HUMATS will definitely try to make contact
    n_contacts_this_day < allowed_contacts_per_day       ; HUMATS are allowed to make contact
                                                         ; HUMATS with 'no-contact' have a probability to make contact
  ]
  [
    let contact-made? False

    if count (my-links with [not (color = green)]) != 0[
      ask one-of my-links with [not (color = green)]  [  ; ask one of the links that is not yet in active contact with me

        if make_contact_probability > random 101 [  ; random 101 because it takes a random integer between 0 and 100 (i.e., lower than the value 101)

          ask other-end [  ; Other end has to 'accept' the contact
            if behaviour = "contact" or
            n_contacts_this_day < allowed_contacts_per_day or
            (behaviour = "no-contact" and no_contact_accept_probability > random 101)  [ ; random 101 because it takes a random integer between 0 and 100 (i.e., lower than the value 101)
              set contact-made? True
              set n_contacts_this_day n_contacts_this_day + 1
              if n_contacts_this_day > allowed_contacts_per_day [
                set opinion_difference_this_day opinion_difference_this_day - random-float (opinion_measure * break-the-rule-effect)   ; Slightly decrease opinion if HUMAT decides to not follow the rule (percentage wise),
                                                                                                                                       ; HUMATs who are more in favor of the rule, yet break the rule, will lower their opinion more
              ]
            ]
          ]

          if contact-made? [set color green]  ; color the link if contact was made

        ]
      ]
    ]

    if contact-made? [
      set n_contacts_this_day n_contacts_this_day + 1
      if n_contacts_this_day > allowed_contacts_per_day [
        set opinion_difference_this_day opinion_difference_this_day - random-float (opinion_measure * break-the-rule-effect)] ; Slightly decrease opinion if HUMAT decides to not follow the rule
    ]
  ]
end


to stop-active-contact
; In this function HUMATS can stop their active connections with friends based on a probability.
  let stop_contact_probability 15   ; Note for this value that both HUMATs may try to stop the same connection
  ask HUMATS [
    ask my-links with [color != 48]
    [
      if stop_contact_probability > random 101 [set color 48] ; random 101 because it takes a random integer between 0 and 100 (i.e., lower than the value 101)
    ]
  ]
end



to apply-day-changes
; After each day (24 hours/tick), changes are applied to HUMATS with regard to opinion and needs
  ask HUMATS [

    ; Opinion changes:
    if n_contacts_this_day < allowed_contacts_per_day [  ; HUMAT has followed the measure this day, so increases opinion a little 'This is not so hard'
                                                         ; Percentage wise added, such that HUMATs who are more against of the rule, yet follow the rule, will increase their opinion more
      set opinion_difference_this_day opinion_difference_this_day + random-float ((100 - opinion_measure) * adhere-to-rule-effect)
    ]

    ; Changes experiential need due to desires:
    ifelse hours_of_contact_this_day < desired_hours_of_contact_this_day  ;
    [set extra_exp_contact extra_exp_contact + extra_exp_satisfaction_per_hour * (desired_hours_of_contact_this_day - hours_of_contact_this_day)]
    [if extra_exp_contact >= extra_exp_satisfaction_per_hour [set extra_exp_contact extra_exp_contact - extra_exp_satisfaction_per_hour * (hours_of_contact_this_day - desired_hours_of_contact_this_day)]]

    if extra_exp_contact >= 1 [set extra_exp_contact 1]
    if extra_exp_contact < 0 [set extra_exp_contact 0]

;    if extra_exp_contact > 0.8 [show extra_exp_contact]

    set hours_of_contact_this_day 0
    set n_contacts_this_day 0

    update-opinions
    ;    update-value-satisfactions
  ]

end


to update-opinions
  ; Adds the stored difference to the opinion of the HUMATS
  set opinion_measure round (opinion_measure + (stubbornness * opinion_difference_this_day))
  set opinion_difference_this_day 0

  ; Opinions should remain between 0 and 100
  ; To avoid all opinions piling up at 0 and 100, a small random value might be added or subtracted instead of set to 100 when opinions go over the limits

  if opinion_measure > 100 [
    set opinion_measure 100
    if 50 > random 101 [set opinion_measure 100 - random 10]   ; random 101 because it takes a random integer between 0 and 100 (i.e., lower than the value 101)
  ]

  if opinion_measure < 0
  [set opinion_measure 0
    if 50 > random 101 [set opinion_measure 0 + random 10]
  ]
end


to count-active-connections
; Counts active contacts
  ask HUMATS
  [ set hours_of_contact_this_day hours_of_contact_this_day + (count my-links with [color = green]) ]
end

to determine-desired-hours
;; HUMATS with more connections will have a higher desire for social contact
  let avg_n_friends (count links * 2 / N-HUMATS) ; Determine the average number of links per HUMAT (*2 since each link counts for two friends)
  ask HUMATS [
    let sigmoid_output (random-normal 10 4)  + (10 / (1 + exp ( - (count link-neighbors - avg_n_friends)))) - 5

    if sigmoid_output > 40 [set sigmoid_output 40]
    if sigmoid_output < 0 [set sigmoid_output 0]
    set desired_hours_of_contact_this_day round(sigmoid_output)
  ]
end


to humat-inquires
  ask HUMATS [
    if random 101 <= inquiry_probability [
      inquire-opinions-from-network   ; if condition is met, humat inquires opinions of its network
    ]
  ]
end

to inquire-opinions-from-network
; Inquires the opinions of friends in the network. This can be used to calculate social satisfaction

  let n_links_to_inquire 1 + random count link-neighbors
  let subset_network n-of n_links_to_inquire link-neighbors
;
  ; Metric 1: Difference from average of network
  let avg_opinion round mean [opinion_measure] of subset_network
  let difference_from_average avg_opinion - opinion_measure

  ; Metric 2: Mean difference from network
  let other_opinions sort [opinion_measure] of subset_network
  let my_opinions n-values (length [opinion_measure] of subset_network)  [opinion_measure]
  let difference_list (map - other_opinions my_opinions)

  foreach range length difference_list [  ; makes sure each item in the list is a positive integer (difference between two value is not negative here)
    [x] ->
    set difference_list replace-item x difference_list abs (item x difference_list)
  ]

  let mean_difference_from_network precision (mean difference_list) 1

  if mean_difference_from_network > 30 or random 101 < mean_difference_from_network  [  ; HUMAT will act depending on the mean difference in its opinion from the network.
                                                                                        ; If the mean difference is higher than 30, it will definitely do an action to resolve differences.
                                                                                        ; Below 30, the probability a HUMAT will perform an action is equal to the value of the mean difference.

    ifelse random 101 > 50   ; HUMAT either tries to convince someone in its network to change their opinion, or adjusts its own opinion to be closer to the average of its network.
    [  signal-to-convince-other subset_network ]   ; try to persuade someone in network
    [  set opinion_difference_this_day opinion_difference_this_day + inquiry-opinion-change * difference_from_average ]  ; adjust own opinion
  ]
end


to signal-to-convince-other [subset_network]
; HUMAT tries to convince someone in the subset of its network to change its opinion towards it

  let others_opinion [opinion_measure] of one-of subset_network
  ;    show others_opinion
  let opinion_diff opinion_measure - others_opinion

  ask one-of subset_network with [opinion_measure = others_opinion]
  [
    ifelse random 101 > 50
    [set opinion_difference_this_day  opinion_difference_this_day + (opinion_diff * inquiry-opinion-change)]  ; 50% probability to convice someone to move its opinion towards that of the HUMAT, could be made dependent of others characteristics.
    [set opinion_difference_this_day  opinion_difference_this_day - (opinion_diff * inquiry-opinion-change)]  ; if the persuasion fails, the opinion of the other diverges from that of the HUMAT
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    PLOTTING & MONITORS     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to update-active-links-plot
  histogram [count my-links with [color = green]] of HUMATS with [count my-links with [color = green] > 0]
end

to update-histogram-plot
  histogram [opinion_measure] of HUMATS
end

to update-active-contacts-average
  if (ticks mod 24) = 0
  [
    plot mean [n_contacts_this_day] of humats
  ]
end

to update-average-contacts-plot
  set-plot-pen-color red
  plot mean [n_contacts_this_day] of HUMATS with [behaviour = "no-contact"]
  set-plot-pen-color green
  plot mean [n_contacts_this_day] of HUMATS with [behaviour = "contact"]

end

to update-colored-histogram-plot
  ; Updates the colored histogram displaying the distribution of opinions
  set-current-plot "Distribution of opinions"
  clear-plot

  let opinion-list n-values 101 [0]  ;101, since 0 is also an opinion

  foreach [opinion_measure] of HUMATS [ i ->
    set opinion-list replace-item i opinion-list (item i opinion-list + 1)
  ]

  ;  show item 100 opinion-list
  let n 101 ;length [opinion_measure] of HUMATS

  set-plot-x-range 0 101
  let step 0.05 ; tweak this to leave no gaps
  (foreach opinion-list range n [ [s i] ->
    let y s
    let c opinion-color (i - 1)
    set-plot-pen-mode 1 ; bar mode
    set-plot-pen-color c
    foreach (range 0 y step) [ _y -> plotxy i  _y ]
    set-plot-pen-color black
    plotxy i y
    set-plot-pen-color c ; to get the right color in the legend
  ])


end

to plot_mean_opinion
  set-plot-pen-color opinion-color mean [opinion_measure] of HUMATS
  plot-pen-up
  plotxy mean [opinion_measure] of HUMATS 0
  plot-pen-down
  plotxy mean [opinion_measure] of HUMATS plot-y-max
end

to-report report_mean_opinion
  report (mean [opinion_measure] of HUMATS)
end


to plot_difference_hours
  if ticks > 24 [
    set-current-plot "Difference Hours - Desired Hours"

    set-plot-pen-mode 1
    histogram [difference_hours] of HUMATS
  ]
end

to plot_difference_hours_mean
  if ticks > 24 [
    set-current-plot "Difference Hours - Desired Hours"
    clear-plot

    set-plot-pen-mode 0 ; line mode
    plot-pen-up
    plotxy 0 0
    plot-pen-down
    plotxy 0 plot-y-max

  ]
end

to plot_mean_difference_hours_humats

  if ticks > 24 [
    set-current-plot "Difference Hours - Desired Hours"
    set mean_difference_in_hours mean [difference_hours] of HUMATS

    set-plot-pen-mode 0 ; line mode
    plot-pen-up
    plotxy mean_difference_in_hours 0
    plot-pen-down
    plotxy mean_difference_in_hours plot-y-max
  ]
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      SETUP PROCEDURES      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to make-HUMATS
  ; seting up basic characteristics of HUMATS
  ask patches [set pcolor 8]    ; Patches are slighly grey, such that the connections are visible
  create-turtles N-HUMATS
  [
    set breed HUMATS
    set size 4
    set shape "person"
    set color red
    set n_contacts_this_day 0
    set opinion_difference_this_day 0
    set hours_of_contact_this_day 0

    set extra_exp_contact 0
    set #dilemmas 0
    set desired_n_contacts_this_day 0

    set stubbornness precision (random-float 1.0) 3

    set xcor random 40 - random 40
    set ycor random 40 - random 40
    ;    fd random 1
    set ses random-float 1
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      SOCIAL NETWORKS       ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; This function sets the social networks around the individual HUMATs by creating connections between HUMATS
to set-social-networks-limited
  ; each HUMAT has at least one link with an alter
  ask HUMATS [
    let n_friends random-normal-trunc 2 2 1 10
    set n_friends round n_friends

    let distance-for-friends 15
    let topological-neighbours other HUMATS with [distance myself <= distance-for-friends]  ;  Shows friends close to each other topologically

    while [count topological-neighbours < n_friends] [  ; This loops makes sure there won't be an error for n_friends > topological neighbours
      set distance-for-friends distance-for-friends + 1
      set topological-neighbours other HUMATS with [distance myself <= distance-for-friends]
    ]

    let #topological-neighbours count topological-neighbours
    create-links-with n-of n_friends topological-neighbours [set color 48] ; NOTE this function makes sure a undirected link is not created when it already exists
    if count link-neighbors = 0 [create-link-with min-one-of other HUMATS [distance myself] [set color 48]]

  ]
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  NEEDS AND SATISFACTIONS   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to set-needs-and-satisfactions
  ; in step 1, HUMATS set their initial behavior with the esclusion of social influence, i.e. on the basis their experiential and value satisfactions
  ; in step 2, HUMATS add the social satisfaction to the calculation of satisfactions from various behavioural alternatives

  ask HUMATS [
    ; STEP 1
    ; set importances
    ifelse parametrize-importances? [  ; Either set importances manually
      set experiential-importance experiential-importance-parameter
      set values-importance values-importance-parameter
    ]
    [  ; Or determine from normal distribution
      set experiential-importance random-normal-trunc 0.5 0.14 0 1
      ;    set social-importance random-normal-trunc 0.5 0.14 0 1
      set values-importance random-normal-trunc 0.5 0.14 0 1
    ]


    ; set initial satisfactions for BA1 (contact) and BA2 (no-contact) ; excluding social dimension
    ; contact
    set experiential-satisfaction-contact random-normal-trunc 0 0.40 -1 1 ; experiential satisfaction -> a person with more connections in its network will yield more satisfaction from having a contact
    set values-satisfaction-contact random-normal-trunc 0 0.40 -1 1

    ; no-contact
    set experiential-satisfaction-no-contact random-normal-trunc 0 0.40 -1 1   ; experiential satisfaction -> feeling of safety when not having contact is determined from a normal distribution
    set values-satisfaction-no-contact random-normal-trunc 0 0.40 -1 1

    ; opinion influence on values satisfaction
    set opinion_values_influence  values_satisfaction_opinion_contribution * (opinion-to-value opinion_measure) ; Opinion influences values satisfaction

    ; set evaluations = importances * satisfactions ; excluding social dimension

    ; contact
    set experiential-evaluation-contact experiential-importance * (experiential-satisfaction-contact + extra_exp_contact)
    set values-evaluation-contact values-importance * (values-satisfaction-contact - opinion_values_influence) ; high opinion means more inclined to follow rules, so it influences contact negatively
                                                                                                               ; no-contact
    set experiential-evaluation-no-contact experiential-importance * (experiential-satisfaction-no-contact - extra_exp_contact)
    set values-evaluation-no-contact values-importance * (values-satisfaction-no-contact + opinion_values_influence)


    set evaluations-list-contact (list (experiential-evaluation-contact) (values-evaluation-contact))
    set evaluations-list-no-contact (list (experiential-evaluation-no-contact) (values-evaluation-no-contact))

    ; set satisfactions from BAs ; excluding social dimension
    set satisfaction-contact (experiential-evaluation-contact + values-evaluation-contact) / 2
    set satisfaction-no-contact (experiential-evaluation-no-contact + values-evaluation-no-contact) / 2

    ifelse satisfaction-contact < satisfaction-no-contact
    [set behaviour "no-contact"] [
      ifelse satisfaction-contact = satisfaction-no-contact [
        set behaviour one-of (list "contact" "no-contact")]
      [set behaviour "contact"]
    ]
  ]
end


to evaluate-and-choose-behavior ; HUMAT-oriented

  ; The BA comparison dimensions include:
  ;* overall satisfaction - if similarly satisfying (+/- 0.2 = 10% of the theoretical satisfaction range <-1;1>), then
  ;* dissonance level - if similarily dissonant (+/- 0.1 = 10% of the theoretical dissonance range <0;1>), then
  ;* satisfaction on experiential need - if similarly satisfying on experiantial need (+/- 0.2 = 10% of the theoretical experiantial satisfaction range <-1;1>), then
  ;* random choice.

  ask HUMATS [
    ;First evaluate 'contact' and 'no contact' according to the experiential and value needs

    ; set evaluations = importances * satisfactions ; excluding social dimension
    ; contact
    set opinion_values_influence  values_satisfaction_opinion_contribution * (opinion-to-value opinion_measure) ; Opinion influences values satisfaction

    ; set evaluations = importances * satisfactions ; excluding social dimension

    ; contact
    set experiential-evaluation-contact experiential-importance * (experiential-satisfaction-contact + extra_exp_contact)
    set values-evaluation-contact values-importance * (values-satisfaction-contact - opinion_values_influence) ; high opinion means more inclined to follow rules, so it influences contact negatively
                                                                                                               ; no-contact
    set experiential-evaluation-no-contact experiential-importance * (experiential-satisfaction-no-contact - extra_exp_contact)
    set values-evaluation-no-contact values-importance * (values-satisfaction-no-contact + opinion_values_influence)

    ; Set satisfaction levels for contact and no contact ; excluding social dimension
    set satisfaction-contact (experiential-evaluation-contact + values-evaluation-contact) / 2
    set satisfaction-no-contact (experiential-evaluation-no-contact + values-evaluation-no-contact) / 2

    ; Determine which behavior to choose
    ifelse satisfaction-contact < satisfaction-no-contact
    [set behaviour "no-contact"] [
      ifelse satisfaction-contact = satisfaction-no-contact [
        set behaviour one-of (list "contact" "no-contact")]
      [set behaviour "contact"]
    ]
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   OPINION INITIALIZATION   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to set-opinions
  ; sets the initial opinion on the COVID visitor measures of the HUMATS
  ifelse initialization = "random uniform" [
    output-print "Opinions initialized randomly"
    ask HUMATS [
      set opinion_measure random 101  ; If no file is found, set random opinions
    ]
  ]
  [
    carefully [  ; catch an error if no csv file is found

      let filename "Data_Draagvlak_Bezoekers.csv"          ; Import RIVM survey data
      let data (csv:from-file filename ",")
      ;  print data
      let data-matrix matrix:from-row-list  data
      ;        print data-matrix
      ;  print matrix:dimensions data-matrix

      let wave 0 ;Circumvents warning of not having a wave selected

      (ifelse ;determine the wave of the survey
        initialization = "RIVM survey: 19-23 aug 2020" [
          set wave 0
          output-print "Opinions initialized from RIVM survey: 19-23 aug 2020"
        ]
        initialization ="RIVM survey: 30 sep - 4 oct 2020" [
          set wave 1
          output-print "Opinions initialized from RIVM survey: 30 sep - 4 oct 2020"
        ]
        initialization ="RIVM survey: 11-15 nov 2020"[
          set wave 2
          output-print "Opinions initialized from RIVM survey: 11-15 nov 2020"
        ]
        initialization ="RIVM survey: 30 dec 2020 - 3 jan 2021"[
          set wave 3
          output-print "Opinions initialized from RIVM survey: 30 dec 2020 - 3 jan 2021"
        ]
        initialization ="RIVM survey: 10-14 feb 2021"[
          set wave 4
          output-print "Opinions initialized from RIVM survey: 10-14 feb 2021"
        ]
        initialization = "RIVM survey: 24-28 mar 2021"[
          set wave 5
          output-print "Opinions initialized from RIVM survey: 24-28 mar 2021"
      ])

      let geen_mening matrix:get data-matrix wave 0
      let helemaal-niet matrix:get data-matrix wave 1
      let niet matrix:get data-matrix wave 2
      let neutraal matrix:get data-matrix wave 3
      let wel matrix:get data-matrix wave 4
      let helemaal-wel matrix:get data-matrix wave 5


      output-print (geen_mening + helemaal-niet + niet + neutraal + wel + helemaal-wel)  ; sum should be 1000
                                                                                         ;        output-print "Opinions initialized from csv datafile"


      ; Each HUMAT determines its opinion as a probability from the csv file
      ask HUMATS [
        ;    set opinion_measure random 101

        let random_number random-float 100
        (ifelse    ; This switch-case determines the initial opinion of a HUMAT, based on the RIVM survey data
          random_number <= geen_mening [
            set opinion_measure random 101     ; random 101 because it takes a random integer between 0 and 100 (i.e., lower than the value 101)
            ;            show "geen mening"
          ]
          random_number > geen_mening and random_number <= helemaal-niet [
            set opinion_measure random 20
            ;        print "helemaal niet"
          ]
          random_number > (geen_mening + helemaal-niet) and random_number <= (helemaal-niet + niet) [
            set opinion_measure 20 + random 20
            ;        print "niet"
          ]
          random_number > (geen_mening + helemaal-niet + niet) and random_number <= (helemaal-niet + niet + neutraal) [
            set opinion_measure 40 + random 20
            ;        print "neutraal"
          ]

          random_number > (geen_mening + helemaal-niet + niet + neutraal) and random_number <= (helemaal-niet + niet + neutraal + wel) [
            set opinion_measure 60 + random 20
            ;        print "neutraal"
          ]
          ; elsecommands
          [
            set opinion_measure 80 + random 20
            ;        print "helemaal-wel"
        ])
      ]
    ]
    [
      output-print "No csv file found - opinions set randomly"
      ask HUMATS [
        set opinion_measure random 101  ; If no file is found, set random opinions ; random 101 because it takes a random integer between 0 and 100 (i.e., lower than the value 101)
      ]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      HELPER FUNCTIONS      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; reports a number from random distribution between two values
to-report random-normal-trunc [mid dev mmin mmax]
  ; creating a trunc normal function to be used for tuncating the normal distribution between mmin and mmax values
  ; good for now, but the goeal would be to get to the normal from beta (using gamma as a start)
  let result random-normal mid dev
  if result < mmin or result > mmax
  [report random-normal-trunc mid dev mmin mmax]
  report result
end


; converts opinion to a value satisfaction on a -1 to 1 scale
to-report opinion-to-value [opinion]
  let opinion_influnce 0.5
  let new_value ((opinion * 2) - 100) / 100
  report new_value * opinion_influnce
end

; converts value satisfaction to 0-100 scale
to-report value-to-opinion [value]
  let new_opinion ((value * 100) + 100) / 2
  report round new_opinion
end

to determine-color
  ask HUMATS [
    set color opinion-color opinion_measure
  ]
end

to-report opinion-color [opinion]
  ;green = 64-68, red = 14-18
  ifelse opinion >= 50 [ ;positive > green
    report precision (69 - ((opinion - 50) * 5 / 50)) 1
  ]
  [ ; negative > red
    report precision (14 + (opinion * 5 / 50)) 1
  ]
end


to check-dilemmas
  ask HUMATS [
    ifelse abs (satisfaction-contact - satisfaction-no-contact) < dilemma_threshold [
      set in_dilemma? TRUE
      set behaviour one-of (list "contact" "no-contact")
      set #dilemmas #dilemmas + 1]
    [ set in_dilemma? FALSE ]
  ]
  set percentage_in_dilemma count humats with [in_dilemma?] / N-HUMATS
end

to-report opinion-reports
  let opinion_list [opinion_measure] of HUMATS
  foreach opinion_list [
    [x] ->
    report x
  ]
end

to-report opinion-per-day
  if ticks > 0 and ticks mod 24 = 0 [
   report [opinion_measure] of HUMATS
  ]
end


to-report mean-opinion-per-day
  if ticks > 0 and ticks mod 24 = 0 [
   report mean [opinion_measure] of HUMATS
  ]
end




;;;;;;; unused functions , but might be helpful later;;;;;;;;;;;

;to-report stop-condition
;; Potential stop condition, but probably won't ever be met since changes happend each tick
;  if ticks >= 200 and ticks mod 100 = 0 [
;    if opinion_check = sort [opinion_measure] of HUMATS [
;      output-print "no change in opinions in 100 ticks, simulation stopped at tick:" output-print ticks
;      report TRUE]
;  ]
;
;  if ticks mod 100 = 0 [
;    set opinion_check sort [opinion_measure] of HUMATS
;    ;  output-print opinion_check
;  ]
;  report FALSE
;end
@#$#@#$#@
GRAPHICS-WINDOW
562
66
1124
629
-1
-1
6.09
1
10
1
1
1
0
0
0
1
-45
45
-45
45
1
1
1
ticks
30.0

SLIDER
21
250
145
283
min_attraction_dif
min_attraction_dif
0
max_attraction_dif
25.0
1
1
NIL
HORIZONTAL

SLIDER
22
216
146
249
max_attraction_dif
max_attraction_dif
0
100
50.0
1
1
NIL
HORIZONTAL

SWITCH
21
285
145
318
repulsion?
repulsion?
0
1
-1000

SLIDER
21
319
145
352
repulsion_dif
repulsion_dif
max_attraction_dif
100
50.0
1
1
NIL
HORIZONTAL

TEXTBOX
154
221
283
297
HUMATs will update their opinion if the difference to another HUMAT is between min_opinion_dif and max_opinion_dif
11
0.0
1

TEXTBOX
152
297
280
358
With repulsion on, opinions diverge when difference is higher than repulsion_dif
11
0.0
1

BUTTON
483
67
546
100
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
812
17
960
49
Model
30
0.0
1

BUTTON
561
20
637
53
go (1 hour)
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
640
20
730
53
go forever
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
563
583
644
628
activated links
count links with [color = green]
17
1
11

MONITOR
644
583
725
628
% activated
100 * (count links with [color = green] )/ (count links)
2
1
11

MONITOR
1012
67
1069
112
NIL
day
17
1
11

MONITOR
1066
67
1123
112
NIL
hour
17
1
11

PLOT
1129
172
1521
388
Distribution of opinions
Opinion value
Frequency
0.0
100.0
0.0
15.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "update-colored-histogram-plot "
"pen-1" 1.0 0 -7500403 true "" "plot_mean_opinion"

PLOT
560
650
801
827
Contacts distribution
Number of contacts
Frequency
0.0
10.0
0.0
50.0
true
true
"" ""
PENS
"contacts" 1.0 0 -1184463 true "" "histogram [count my-links] of HUMATS"
"active" 1.0 1 -14439633 true "" "update-active-links-plot"

SLIDER
22
158
192
191
allowed_contacts_per_day
allowed_contacts_per_day
1
10
2.0
1
1
NIL
HORIZONTAL

TEXTBOX
213
161
476
217
Visitors-measure strength, allowed number of activated connections for an agent per day
11
0.0
1

TEXTBOX
1468
12
1618
49
Output
30
0.0
1

TEXTBOX
11
799
526
827
(possible extensions: fear, dynamic model, parties, QR code + events)
11
0.0
1

CHOOSER
23
109
193
154
initialization
initialization
"random uniform" "RIVM survey: 19-23 aug 2020" "RIVM survey: 30 sep - 4 oct 2020" "RIVM survey: 11-15 nov 2020" "RIVM survey: 30 dec 2020 - 3 jan 2021" "RIVM survey: 10-14 feb 2021" "RIVM survey: 24-28 mar 2021"
3

MONITOR
1442
127
1521
172
%V support
count HUMATS with [opinion_measure >= 80]/ count HUMATS * 100
1
1
11

MONITOR
1371
127
1443
172
% support
count HUMATS with [60 <= opinion_measure and opinion_measure < 80]/ count HUMATS * 100
1
1
11

MONITOR
1209
127
1290
172
% opposed
count HUMATS with [20 <= opinion_measure and opinion_measure < 40]/ count HUMATS * 100
1
1
11

MONITOR
1290
127
1371
172
% neutral
count HUMATS with [40 <= opinion_measure and opinion_measure < 60]/ count HUMATS * 100
1
1
11

MONITOR
1129
127
1210
172
% V opposed
count HUMATS with [opinion_measure < 20] / count HUMATS * 100
1
1
11

TEXTBOX
1133
71
1519
127
To which extent do HUMATS support the maximum visitors measure (higher value equals bigger support):\n\n     20<\t                  20-39                      40-59                 60-79                   >80
11
0.0
1

TEXTBOX
212
108
497
178
This chooser determines the initial distribution of opinions, dependent on RIVM survey data (requires csv data file). Also a random uniform distribution can be chosen
11
0.0
1

PLOT
1524
172
1862
388
Average opinion over time
Time
Average Opinion
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"All" 1.0 0 -16777216 true "" "if ticks > 0 and ticks mod 24 = 0 [ plot mean [opinion_measure] of HUMATS]"
"no-contact" 1.0 0 -13791810 true "" "if ticks > 0 and ticks mod 24 = 0 [ plot mean [opinion_measure] of HUMATS with [behaviour = \"no-contact\"]]"
"contact" 1.0 0 -8630108 true "" "if ticks > 0 and ticks mod 24 = 0 [ plot mean [opinion_measure] of HUMATS with [behaviour = \"contact\"]]"

SLIDER
22
73
194
106
N-HUMATS
N-HUMATS
10
150
100.0
1
1
NIL
HORIZONTAL

TEXTBOX
109
12
386
45
Input Parameters
30
0.0
1

PLOT
801
650
1123
827
Average contacts per day per behaviour
Days
Average contacts
0.0
10.0
0.0
8.0
true
true
"" ""
PENS
"allowed" 1.0 0 -14439633 true "" "if ticks > 0 and ticks mod 24 = 0 [ \n  plot allowed_contacts_per_day \n  ]"
"no-contact" 1.0 0 -13791810 true "" "if  ticks > 0 and ticks mod 24 = 0 [ \n  plot mean [n_contacts_this_day] of HUMATS with [behaviour = \"no-contact\"]]"
"contact" 1.0 0 -8630108 true "" "if ticks > 0 and ticks mod 24 = 0 [ \n  plot mean [n_contacts_this_day] of HUMATS with [behaviour = \"contact\"]]"

MONITOR
1051
721
1122
766
#contact
count humats with [behaviour = \"contact\"]
0
1
11

MONITOR
1051
765
1122
810
#no-contact
count humats with [behaviour = \"no-contact\"]
0
1
11

SLIDER
18
578
192
611
adhere-to-rule-effect
adhere-to-rule-effect
0
.1
0.04
0.002
1
NIL
HORIZONTAL

SLIDER
18
506
192
539
social-influence-per-tick
social-influence-per-tick
0
0.01
0.001
0.001
1
NIL
HORIZONTAL

SLIDER
18
614
191
647
break-the-rule-effect
break-the-rule-effect
0
0.05
0.02
0.001
1
NIL
HORIZONTAL

SLIDER
18
543
193
576
inquiry-opinion-change
inquiry-opinion-change
0
.5
0.2
0.1
1
NIL
HORIZONTAL

SLIDER
17
375
197
408
make_contact_probability
make_contact_probability
0
100
10.0
1
1
NIL
HORIZONTAL

TEXTBOX
209
381
448
423
Probability for HUMATs to attempt making contact at a given tick (when conditions allow it)
11
0.0
1

SLIDER
16
447
196
480
inquiry_probability
inquiry_probability
0
10
1.0
1
1
NIL
HORIZONTAL

TEXTBOX
212
451
423
507
Probability for HUMATs to inquire opinions from their friends (and perform an action)
11
0.0
1

TEXTBOX
51
195
236
227
Social influence conditions:
15
52.0
1

TEXTBOX
78
52
228
71
General:
15
52.0
1

TEXTBOX
52
486
202
505
Opinion effects:
15
52.0
1

TEXTBOX
211
83
361
101
The number of HUMAT agents
11
0.0
1

SLIDER
16
411
197
444
no_contact_accept_probability
no_contact_accept_probability
0
100
20.0
1
1
NIL
HORIZONTAL

TEXTBOX
210
415
425
457
Probability for a HUMAT with 'no contact' behavior to accept a contact attempt\n
11
0.0
1

TEXTBOX
64
356
214
375
Probabilities:
15
52.0
1

MONITOR
1527
126
1604
171
All HUMATS
report_mean_opinion
1
1
11

PLOT
1141
651
1492
827
Difference Hours - Desired Hours
Difference
Frequency
-30.0
30.0
0.0
15.0
true
false
"" ""
PENS
"default" 1.0 1 -1513240 true "" "plot_difference_hours_mean"
"pen-1" 1.0 0 -8275240 true "" "plot_mean_difference_hours_humats"
"pen-2" 1.0 0 -16777216 true "" "plot_difference_hours "

PLOT
1136
419
1494
576
Experiential
NIL
NIL
-1.05
1.05
0.0
25.0
true
true
"" ""
PENS
"S_e contact" 0.05 0 -11085214 true "" "histogram [experiential-satisfaction-contact + extra_exp_contact] of humats"
"S_e no contact" 0.05 0 -2674135 true "" "histogram [experiential-satisfaction-no-contact - extra_exp_contact] of humats"

PLOT
1504
419
1861
575
Values
NIL
NIL
-1.05
1.05
0.0
20.0
true
true
"" ""
PENS
"S_v contact" 0.05 0 -13840069 true "" "histogram [values-satisfaction-contact - opinion_values_influence] of humats"
"S_v no contact" 0.05 0 -2674135 true "" "histogram [values-satisfaction-no-contact + opinion_values_influence] of humats"

TEXTBOX
1313
669
1335
687
0
11
9.0
1

MONITOR
1435
669
1485
714
    AVG
mean_difference_in_hours
2
1
11

SLIDER
12
675
252
708
extra_exp_satisfaction_per_hour
extra_exp_satisfaction_per_hour
0
0.02
0.01
0.001
1
NIL
HORIZONTAL

SLIDER
13
709
251
742
values_satisfaction_opinion_contribution
values_satisfaction_opinion_contribution
0
1
0.5
0.1
1
NIL
HORIZONTAL

PLOT
1501
651
1863
826
HUMATs in dilemma 
Days
Percentage
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if ticks > 0 and ticks mod 24 = 0 [plot percentage_in_dilemma * 100]"

MONITOR
1784
669
1856
714
#in dilemma
percentage_in_dilemma * 100
0
1
11

SLIDER
13
744
251
777
dilemma_threshold
dilemma_threshold
0
0.1
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
301
305
548
338
experiential-importance-parameter
experiential-importance-parameter
0
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
300
340
549
373
values-importance-parameter
values-importance-parameter
0
1
0.5
0.1
1
NIL
HORIZONTAL

SWITCH
301
220
550
253
parametrize-importances?
parametrize-importances?
1
1
-1000

TEXTBOX
372
199
522
218
Importances:
15
52.0
1

TEXTBOX
300
257
556
313
If parametrize-importances? is 'off', importances are drawn from a normal distribution, if 'on' all HUMATS are initialized with importances from the sliders below
11
0.0
1

TEXTBOX
76
656
226
675
Other parameters:
15
52.0
1

TEXTBOX
1483
50
1633
69
Opinions:
15
52.0
1

TEXTBOX
643
630
1045
678
(Active) Contacts distribution and contacts per behaviour:
15
52.0
1

MONITOR
1640
125
1727
170
no-contact
mean [opinion_measure] of HUMATS with [behaviour = \"no-contact\"]
1
1
11

MONITOR
1752
126
1833
171
contact
mean [opinion_measure] of HUMATS with [behaviour = \"contact\"]
1
1
11

TEXTBOX
1416
395
1615
433
Needs and Satisfactions:
15
52.0
1

TEXTBOX
1577
88
1815
116
Average opinions (overall and per behaviour):
11
0.0
1

TEXTBOX
1660
583
1810
618
Dilemmas:
15
62.0
1

TEXTBOX
1530
603
1847
686
HUMATs are in dilemma if the difference between the evaluation for contact and no-contact behavior is smaller than the dilemma_threshold (leads to random behaviour):
11
0.0
1

TEXTBOX
1187
582
1435
620
Desired and Actual hours of contact:
15
52.0
1

TEXTBOX
1152
602
1500
686
Every day, each HUMAT has a desire for contact. This histogram shows the distribution of differences between desired and actual hours of contact per day of all HUMATS (value < 0 means the desire is not met)
11
0.0
1

TEXTBOX
211
507
531
549
This variable determines the extent to which HUMATs in active contact influence the opinion of the other
11
0.0
1

TEXTBOX
209
544
497
572
Opinion change as result of persuasion succes / failure
11
0.0
1

TEXTBOX
209
583
520
611
Opinion increase for adhering to visitors measure on a given day\n
11
0.0
1

TEXTBOX
207
621
534
648
Opinion decrease for breaking the rule (per new active connection on a day that above the allowed contacts for that day)
11
0.0
1

TEXTBOX
259
677
566
747
Experiential satisfaction goes up by this amount per hour of difference between desired hours and actual hours of contact\n
11
0.0
1

TEXTBOX
262
718
506
746
Contribution of opinions to values satisfaction
11
0.0
1

TEXTBOX
263
750
534
806
Determines which difference between the evaluation for contact and no-contact behavior invokes a dilemma
11
0.0
1

SWITCH
969
24
1122
57
stop-at-day-hundred?
stop-at-day-hundred?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

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
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment-reports" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2400"/>
    <metric>sort [opinion_measure] of HUMATs</metric>
    <enumeratedValueSet variable="N-HUMATS">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min_attraction_dif">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialization">
      <value value="&quot;RIVM survey: 24-28 mar 2021&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repulsion_dif">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="break-the-rule-effect">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adhere-to-rule-effect">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inquiry-opinion-change">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="social-influence-per-tick">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repulsion?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no_contact_accept_probability">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max_attraction_dif">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inquiry_probability">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make_contact_probability">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="allowed_contacts_per_day">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-average-100" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2400"/>
    <metric>mean [opinion_measure] of HUMATS</metric>
    <enumeratedValueSet variable="N-HUMATS">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min_attraction_dif">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialization">
      <value value="&quot;RIVM survey: 19-23 aug 2020&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repulsion_dif">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="break-the-rule-effect">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extra_exp_satisfaction_per_hour">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adhere-to-rule-effect">
      <value value="0.04"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inquiry-opinion-change">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="social-influence-per-tick">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repulsion?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max_attraction_dif">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no_contact_accept_probability">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="values_satisfaction_opinion_contribution">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inquiry_probability">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make_contact_probability">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="allowed_contacts_per_day">
      <value value="6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="single_run" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2400"/>
    <metric>sort [opinion_measure] of HUMATs</metric>
    <enumeratedValueSet variable="N-HUMATS">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min_attraction_dif">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialization">
      <value value="&quot;RIVM survey: 11-15 nov 2020&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repulsion_dif">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dilemma_threshold">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="break-the-rule-effect">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adhere-to-rule-effect">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inquiry-opinion-change">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extra_exp_satisfaction_per_hour">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="social-influence-per-tick">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repulsion?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max_attraction_dif">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no_contact_accept_probability">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="values_satisfaction_opinion_contribution">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inquiry_probability">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make_contact_probability">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="allowed_contacts_per_day">
      <value value="2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="100_runs_average" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2400"/>
    <metric>mean [opinion_measure] of HUMATs</metric>
    <enumeratedValueSet variable="N-HUMATS">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min_attraction_dif">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialization">
      <value value="&quot;RIVM survey: 24-28 mar 2021&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repulsion_dif">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dilemma_threshold">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="break-the-rule-effect">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adhere-to-rule-effect">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inquiry-opinion-change">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extra_exp_satisfaction_per_hour">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="social-influence-per-tick">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repulsion?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max_attraction_dif">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no_contact_accept_probability">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="values_satisfaction_opinion_contribution">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inquiry_probability">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make_contact_probability">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="allowed_contacts_per_day">
      <value value="1"/>
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
