path = require 'path'

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

  getRoute: (app, route) ->
    switch typeof app.permissions[route]
      when 'undefined'
        return @getRoute(app, path.join(route, '..').replace(/\\/g, '/'))
      when 'object'
        return route

  checkObject: (object, locals) ->
    for key in Object.keys(object)
      switch typeof object[key]
        when 'object'
          return @checkObject(object[key], locals[key])
        else
          return (object[key] == locals[key])


module.exports = ExpressPermissions
