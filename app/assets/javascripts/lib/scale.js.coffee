define [
  'underscore'
], (_) ->
  'use strict'

  # Scaling maps

  # A scaling map like this:
  #   640: 1
  #   1024: 2
  #   max: 3
  # means:
  #   if size <= 640, return 1
  #   if size <= 1024 return 2
  #   otherwise (size > 1024), return 3

  MAPS =

    # Chart
    # ------

    chartRadius:
      340: 0.22
      380: 0.26
      400: 0.28
      620: 0.30
      900: 0.34
      1000: 0.36
      max: 0.38

    chartRadiusOneOnly:
      320: 0.22
      380: 0.26
      400: 0.28
      460: 0.30
      540: 0.32
      690: 0.34
      750: 0.36
      800: 0.38
      1000: 0.40
      max: 0.42

    chartRadiusOneToOne:
      320: 0.22
      380: 0.26
      400: 0.28
      460: 0.30
      540: 0.32
      690: 0.34
      750: 0.36
      800: 0.38
      1000: 0.40
      max: 0.42

    chartRadiusThumbnail:
      max: 0.3

    # Used for charts with 3, 5 and 7 magnets
    chartYOffset:
      520: 12
      600: 18
      640: 24
      max: 32

    # Magnet
    # ------

    magnetSize:
      300: 13
      520: 16
      max: 20

    magnetSizeUpToTwo:
      320: 20
      520: 40
      800: 50
      max: 100

    magnetLabelSize:
      300: 10
      520: 10
      max: 12

    magnetLabelSizeUpToTwo:
      300: 10
      520: 12
      max: 15

    magnetLabelXOffsetUpToTwo:
      300: 1
      520: 2
      max: 8

    # Country label
    # -------------

    countryLabelSize:
      300: 12
      520: 14
      max: 17

    # Indicators
    # ----------

    indicatorDistance:
      300: 10
      520: 15
      max: 20

    indicatorHeight:
      300: 12
      520: 18
      800: 25
      1000: 30
      max: 35

    visualizationSize:
      300: 8
      520: 12
      800: 20
      1000: 25
      max: 30

    visualizationSizeNineToAll:
      300: 5
      520: 10
      800: 14
      1000: 18
      max: 20

    # Indicator top and bottom position:
    # x offset for horizontal centering
    indicatorIndent:
      300: -25
      520: -35
      max: -45

    indicatorFontSize:
      520: 10
      800: 12
      1000: 13
      max: 14

    indicatorTopPadding:
      800: 2
      1000: 4
      max: 6

  # Transform maps into sorted array of objects
  # MAPS = {
  #   mapName: [
  #     { threshold: 123, value: 123 },
  #     …
  #     { threshold: 'max', value: 456 },
  #   ],
  #   …
  # }
  MAPS = do ->
    newMaps = {}
    sorter = (a, b) ->
      a = Infinity if a is 'max'
      b = Infinity if b is 'max'
      a - b
    for mapName, map of MAPS
      thresholds = _(map).keys().sort(sorter)
      rules = []
      for threshold in thresholds
        rules.push { threshold, value: map[threshold] }
      newMaps[mapName] = rules
    newMaps

  # Scale a unit according to a given size and a threshold map
  (mapName, size) ->
    unless typeof mapName is 'string'
      throw new Error 'Scale: Map name must be given'
    unless typeof size is 'number'
      throw new Error 'Scale: Size must be given'
    map = MAPS[mapName]
    unless map
      throw new Error "Scale: Map data for #{mapName} not found"
    for rule in map
      threshold = rule.threshold
      if threshold is 'max' or size <= threshold
        return rule.value
    return
