path = require 'path'

Layer = require path.join(__dirname, '..', 'node_modules', 'express', 'lib', 'router', 'layer')

ExpressPermissions =
  middleware: ->
    (request, response, next) ->
      check = ExpressPermissions.check(request, response)
      switch typeof check
        when 'object'
          check.then (value) ->
            if value
              next()
            else
              response.status(403).end()

        else
          if check
            next()
          else
            response.status(403).end()

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
    check = request.app.permissions[@getRoute(request.app, request.originalUrl)]
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
      return route if layer.match(url)

    switch typeof app.permissions[url]
      when 'undefined'
        return @getRoute(app, path.join(url, '..').replace(/\\/g, '/'))
      when 'object'
        return url

  checkObject: (object, locals) ->
    for key in Object.keys(object)
      switch typeof object[key]
        when 'object'
          return @checkObject(object[key], locals[key])
        else
          return (object[key] == locals[key])


module.exports = ExpressPermissions
