#= require ./deparam

$ ->
  approxEqual = (point1, point2) ->
    return false unless point1 && point2
    point1.lat().toPrecision(6) == point2.lat().toPrecision(6) && point2.lng().toPrecision(6) == point2.lng().toPrecision(6)

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
      if response.routes.length == 0
        return alert("Google maps was unable to find a route between #{response.request.origin} and #{response.request.destination}. Error code: #{status}")
      i = 0
      points = []
      instructions = []
      $('#directions-summary').html('')
      prevPoint = null

      response.routes[0].legs.forEach (leg) ->
        $('#directions-summary').append("#{leg.distance.text}, #{leg.duration.text}")
        leg.steps.forEach (step) ->
          instructions.push([i, "#{step.instructions} (#{step.distance.text})"])
          step.lat_lngs.forEach (point) ->
            unless approxEqual(point, prevPoint)
              points.push(point)
              prevPoint = point
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

    percentThrough = 100*stepIndex/(1.0*(pointsOfView.length-1))
    $('#video-controls .progress-indicator-fixed').css('width', Math.max(percentThrough, 1)+'%')

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
        progress = 100*(stepsSoFar/(1.0*stepsTotal))
        $progress.css 'width', Math.max(progress, 1)+'%'

      $progress.appendTo $item
      $item.appendTo $list

  prevImage = ->
    window.stepIndex = Math.max(stepIndex-1, 0)
    updateMaps()

  nextImage = ->
    window.stepIndex = Math.min(stepIndex+1, pointsOfView.length-1)
    updateMaps()

  $('#video-controls .progress-indicator-wrapper').click (e) ->
    percentThrough = (e.pageX-$(@).offset().left) / (1.0*$(@).width())
    window.stepIndex = Math.floor(percentThrough*(pointsOfView.length-1))
    updateMaps()

  $('#video-controls .progress-indicator-wrapper').mousemove (e) ->
    percentThrough = 100*((e.pageX-$(@).offset().left) / (1.0*$(@).width()))
    $('.progress-indicator-hover').css 'width', Math.max(percentThrough, 1)+'%'

  $('#video-controls .progress-indicator-wrapper').mouseleave (e) ->
    $('.progress-indicator-hover').css 'width', 0

  $('#prev-image').click prevImage
  $('#next-image').click nextImage

  $('#prev-waypoint').click ->
    prev = 0
    for inst in instructions.slice(0).reverse()
      if inst[0] < stepIndex
        prev = inst[0]; break
    window.stepIndex = prev
    updateMaps()

  $('#next-waypoint').click ->
    next = pointsOfView.length-1
    for inst in instructions
      if inst[0] > stepIndex
        next = inst[0]; break
    window.stepIndex = next
    updateMaps()

  $('#play').click ->
    if $(@).hasClass('is-paused')
      window.stepInterval = setInterval(nextImage, 1000)
      $(@).text('❚❚')
      $(@).removeClass('is-paused')
    else
      clearInterval(window.stepInterval)
      $(@).text('►')
      $(@).addClass('is-paused')

  $('#submit').click ->
    originAddress = $('#origin').val()
    destinationAddress = $('#destination').val()
    travelMode = $('#travel-mode').val()
    request = {
      origin: originAddress,
      destination: destinationAddress,
      travelMode: travelMode
    }
    newHref = location.origin + '?' + $.param(request)
    history.replaceState({}, document.title, newHref)
    requestRoute(request)
    false

  $('body').on 'click', '#text-directions a', ->
    window.stepIndex = parseInt($(@).attr('data-index'))
    updateMaps()

  if window.location.search
    params = $.deparam(window.location.search.replace(/^\?/, ''))
    $('#origin').val(params.origin) if params.origin
    $('#destination').val(params.destination) if params.destination
    $('#travel-mode').val(params.travelMode) if params.travelMode

  $('#submit').click()
