path = require 'path'

Layer = require path.join(require.resolve('express'), '..', 'lib', 'router', 'layer')

ExpressPermissions =
  middleware: ->
    (request, response, next) ->
      check = ExpressPermissions.check(request, response)
      switch typeof check
        when 'object'
          check.then (value) ->
            ExpressPermissions.produceError(value, request, response, next)
        else
          ExpressPermissions.produceError(check, request, response, next)

  produceError: (value, request, response, next) ->
    if value
      next()
    else
      response.status(403)
      if request.app.permissionDenied
        request.app.permissionDenied.call(request.app, request, response)
      else
        response.end()

  add: (app, route, value, promise = false) ->
    app.permissions ||= {}
    throw "#{route} already has permissions" unless typeof app.permissions[route] is 'undefined'
    app.permissions[route] = {
      typeof: typeof value
      route: route
      value: value
      promise: promise
    }


  check: (request, response) ->
    foundRoute = @getRoute(request.app, request.originalUrl)
    request.params = foundRoute.params
    check = request.app.permissions[foundRoute.route]
    switch check.typeof
      when 'boolean'
        return check.value
      when 'object'
        return @checkObject(check.value, response.locals)
      when 'function'
        if check.promise
          return new Promise(
            (resolve, reject) ->
              check.value.call(request.app, request, response, resolve, reject)
          )
        else
          return check.value.call(request.app, request, response)

  getRoute: (app, url) ->
    routes = Object.keys(app.permissions)
    for route in routes
      layer = new Layer(route, {}, ->)
      if layer.match(url)
        object = {
          route: route
          params: layer.params
        }
        return object

    switch typeof app.permissions[url]
      when 'undefined'
        return @getRoute(app, path.join(url, '..').replace(/\\/g, '/'))

  checkObject: (object, locals) ->
    for key in Object.keys(object)
      switch typeof object[key]
        when 'object'
          return @checkObject(object[key], locals[key])
        else
          return (object[key] == locals[key])


module.exports = ExpressPermissions
