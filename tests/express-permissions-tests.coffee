path = require 'path'
expect = require('chai').expect

if /lib-cov/.test(__dirname)
  ExpressPermissions = require path.join(__dirname, '..', 'express-permissions.js')
else
  ExpressPermissions = require path.join(__dirname, '..')

app = {}
request = {}
response = {
  locals: {
    foo: {
      bar: 'widget'
    }
  }
  _status: 200
  status: (newStatus) ->
    response._status = newStatus
    return response

  end: ->
}

describe 'ExpressPermissions', ->
  beforeEach ->
    request.app = app

  describe 'add', ->
    it 'should add permissions to app', ->
      ExpressPermissions.add(app, '/', true)

      expect(app.permissions.where({route: '/'})[0].value).to.equal true
      expect(app.permissions.where({route: '/'})[0].promise).to.equal false

    it 'should travel upwards', ->
      request.originalUrl = '/some/deep/route/with/no/permissions'

      expect(ExpressPermissions.check(request, response)[0]).to.equal true

  describe 'Synchronous', ->
    it 'should create a boolean check', ->
      ExpressPermissions.add(app, '/boolean', true)

      request.originalUrl = '/boolean'

      expect(ExpressPermissions.check(request, response)[0]).to.equal true

    it 'should create a object check', ->
      ExpressPermissions.add(app, '/object', {foo: {bar: 'widget'}})

      request.originalUrl = '/object'

      expect(ExpressPermissions.check(request, response)[0]).to.equal true

    it 'should return false if keys dont exist', ->

      ExpressPermissions.add(app, '/object/undefined', {widget: {bar: 'widget'}})

      request.originalUrl = '/object/undefined'

      expect(ExpressPermissions.check(request, response)[0]).to.equal false

      ExpressPermissions.add(app, '/object/undefined2', {missing: 'foo'})

      request.originalUrl = '/object/undefined2'

      expect(ExpressPermissions.check(request, response)[0]).to.equal false


    it 'should create a function check', ->
      ExpressPermissions.add(app, '/function', (request, response) -> true)

      request.originalUrl = '/function'

      expect(ExpressPermissions.check(request, response)[0]).to.equal true

  describe 'Asynchronous', ->
    it 'should accept a promise flag', ->
      ExpressPermissions.add(app, '/promise', (request, response, resolve, reject) ->
        expect(response.locals.foo.bar).to.equal 'widget'
        resolve(true)
      , {promise: true})

      expect(app.permissions.where({route: '/promise'})[0].promise).to.equal true

    it 'should run the promise', (done) ->
      request.originalUrl = '/promise'

      ExpressPermissions.check(request, response)[0].then (result) ->
        expect(result).to.equal true
        done()

  describe 'Options', ->
    it 'should default promise to false', ->
      ExpressPermissions.add(app, '/options/promiseIsFalse', true)

      expect(app.permissions.where({route: '/options/promiseIsFalse'})[0].promise).to.equal false

  describe 'Middleware', ->
    [func] = []

    beforeEach ->
      func = ExpressPermissions.middleware()
      response._status = 200

    it 'should work synchronously', ->
      request.originalUrl = '/boolean'

      func(request, response, -> )

    it 'should work asynchronously', (done) ->
      request.originalUrl = '/promise'

      func(request, response, done)


    it 'should cause an error 403', ->
      ExpressPermissions.add(app, '/boolean/false', false)

      request.originalUrl = '/boolean/false'

      func(request, response, ->
        throw 'Test Failed'
      )

      expect(response._status).to.equal 403

    it 'should cause an error 403 by Promise', (done) ->
      ExpressPermissions.add(app, '/promise/false', (request, response, resolve, reject) ->
        resolve(false)
      , {promise: true})

      request.originalUrl = '/promise/false'

      func(request, response, ->
        throw 'Test Failed'
      )

      setTimeout(->
        expect(response._status).to.equal 403
        done()
      , 10)

    it 'should run your error function if it exists', (done) ->
      app.permissionDenied = (request, response) ->
        done()

      func(request, response, ->
        throw 'Test Failed'
      )

    it 'should use a custom denied error', (done) ->
      ExpressPermissions.add(app, '/custom/error', false, {denied: (request, response) -> done()})

      request.originalUrl = '/custom/error'

      app.permissionDenied = (request, response) ->
        throw 'Test Failed 1'

      func(request, response, ->
        throw 'Test Failed 2'
      )

  describe 'Layer', ->
    it 'should match /layer/:param', ->
      ExpressPermissions.add(app, '/layer/:param', false)

      request.originalUrl = '/layer/foo'

      expect(ExpressPermissions.check(request, response)[0]).to.equal false

    it 'should supply the params', ->
      ExpressPermissions.add(app, '/params/:supplied', (request, response) ->
        (request.params.supplied == 'foo')
      )

      request.originalUrl = '/params/foo'

      expect(ExpressPermissions.check(request, response)[0]).to.equal true
