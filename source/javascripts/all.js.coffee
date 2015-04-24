$ ->
  bearingBetween = (point1, point2) ->
    lat1 = point1.lat()*(Math.PI / 180.0)
    lon1 = point1.lng()*(Math.PI / 180.0)
    lat2 = point2.lat()*(Math.PI / 180.0)
    lon2 = point2.lng()*(Math.PI / 180.0)

    y = Math.sin(lon2-lon1) * Math.cos(lat2)
    x = Math.cos(lat1)*Math.sin(lat2) -
      Math.sin(lat1)*Math.cos(lat2)*Math.cos(lon2-lon1)

    return Math.atan2(y, x)*(180.0 / Math.PI)

  fenway = new google.maps.LatLng(42.345573,-71.098326)

  window.directionsService = new google.maps.DirectionsService()
  window.streetViewMap = new google.maps.StreetViewPanorama(document.getElementById('streetview-map'), position: fenway)
  window.birdsEyeMap = new google.maps.Map(document.getElementById('birdseye-map'), center: fenway, zoom: 14)
  window.directionsRenderer = new google.maps.DirectionsRenderer()
  window.mapMarker = new google.maps.Marker(position: fenway)
  mapMarker.setMap(birdsEyeMap)
  directionsRenderer.setMap(birdsEyeMap)

  requestRoute = (request) ->
    directionsService.route request, (response, status) ->
      i = 0
      points = []
      instructions = []

      response.routes[0].legs.forEach (leg) ->
        leg.steps.forEach (step) ->
          instructions.push([i, step.instructions])
          step.lat_lngs.forEach (point) ->
            points.push(point)
            i += 1

      pointsWithBearings = []
      points.forEach (point, i) ->
        if i == 0
          bearing = bearingBetween(point, points[i+1])
        else if i == points.length-1
          bearing = bearingBetween(points[i-1], point)
        else
          bearing1 = bearingBetween(points[i-1], point)
          bearing2 = bearingBetween(point, points[i+1])
          bearing = (bearing1 + bearing2)/2.0
        pointsWithBearings.push([point, bearing])

      directionsRenderer.setDirections(response)
      window.instructions = instructions
      window.pointsOfView = pointsWithBearings
      window.stepIndex = 0
      updateMaps()

  updateMaps = ->
    pov = pointsOfView[stepIndex]
    streetViewMap.setPosition(pov[0])
    streetViewMap.setPov(heading: pov[1], pitch: 0)
    birdsEyeMap.setCenter(pov[0])
    birdsEyeMap.setZoom(14)
    mapMarker.setPosition(pov[0])

    $list = $('ul#text-directions')
    $list.html('')
    instructions.forEach (inst, i) ->
      index = inst[0]
      text = inst[1]

      $item = $("<li>")
      $item.html("<span><a href='javascript:void(0)' data-index='"+index+"'>🔗</a>" + text+"</span>")

      if i == instructions.length-1
        nextIndex = pointsOfView.length-1
      else
        nextIndex = instructions[i+1][0]

      $progress = $("<div class='progress-indicator'>")
      if stepIndex >= nextIndex
        $progress.css 'width', '100%'
      else if stepIndex >= index
        stepsTotal = nextIndex - index
        stepsSoFar = stepIndex - index
        $progress.css 'width', 100*(stepsSoFar/(1.0*stepsTotal))+'%'

      $progress.appendTo $item
      $item.appendTo $list

  prevImage = ->
    window.stepIndex = Math.max(stepIndex-1, 0)
    updateMaps()

  nextImage = ->
    window.stepIndex = Math.min(stepIndex+1, pointsOfView.length-1)
    updateMaps()

  $('#prev-image').click prevImage
  $('#next-image').click nextImage

  $('#submit').click ->
    originAddress = $('#origin').val()
    destinationAddress = $('#destination').val()
    travelMode = $('#travel-mode').val()
    request = {
      origin: originAddress,
      destination: destinationAddress,
      travelMode: google.maps.TravelMode[travelMode]
    }
    requestRoute(request)

  $('body').on 'click', '#text-directions a', ->
    window.stepIndex = parseInt($(@).attr('data-index'))
    updateMaps()