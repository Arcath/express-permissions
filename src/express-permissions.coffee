path = require 'path'

Layer = require path.join(require.resolve('express'), '..', 'lib', 'router', 'layer')
sodb = require 'sodb'

ExpressPermissions =
  middleware: ->
    (request, response, next) ->
      checkArray = ExpressPermissions.check(request, response)

      check = checkArray[0]
      checkObject = checkArray[1]

      switch typeof check
        when 'object'
          check.then (value) ->
            ExpressPermissions.produceError(value, request, response, checkObject, next)
        else
          ExpressPermissions.produceError(check, request, response, checkObject, next)

  produceError: (value, request, response, checkObject, next) ->
    if value
      next()
    else
      response.status(403)
      if checkObject.denied
        checkObject.denied.call(request.app, request, response)
      else
        if request.app.permissionDenied
          request.app.permissionDenied.call(request.app, request, response)
        else
          response.end()

  add: (app, route, value, options = {}) ->
    options.promise ||= false
    app.permissions ||= new sodb({cache: true})
    app.permissions.add {
      typeof: typeof value
      route: route
      value: value
      promise: options.promise
      denied: options.denied
    }


  check: (request, response) ->
    foundRoute = @getRoute(request.app, request.originalUrl)
    request.params = foundRoute.params
    check = request.app.permissions.findOne({route: foundRoute.route})
    switch check.typeof
      when 'boolean'
        return [check.value, check]
      when 'object'
        return [@checkObject(check.value, response.locals), check]
      when 'function'
        if check.promise
          promise = new Promise(
            (resolve, reject) ->
              check.value.call(request.app, request, response, resolve, reject)
          )

          return [promise, check]
        else
          return [check.value.call(request.app, request, response), check]

  getRoute: (app, url) ->
    routes = app.permissions.where().map (value) ->
      return value.route
    for route in routes
      layer = new Layer(route, {}, ->)
      if layer.match(url)
        object = {
          route: route
          params: layer.params
        }
        return object

    switch typeof app.permissions.where({route: url})[0]
      when 'undefined'
        return @getRoute(app, path.join(url, '..').replace(/\\/g, '/'))

  checkObject: (object, locals) ->
    for key in Object.keys(object)
      switch typeof object[key]
        when 'object'
          return false if typeof locals[key] is 'undefined'
          return @checkObject(object[key], locals[key])
        else
          return (object[key] == locals[key])


module.exports = ExpressPermissions
