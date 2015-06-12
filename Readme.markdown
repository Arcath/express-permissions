# express-permissions

Easy to use permissions system for Express

## Install

```
npm install express-permissions --save
```

## Usage

Require express-permissions and load it as middleware.

```javascript
ExpressPermissions = require('express-permissions')

app.use(ExpressPermissions.middleware())
```

Middleware is executed in order from first to last, make sure any middleware you will need to run first is added before express-permissions.

### Defining permissions

Permissions are defined by calling `ExpressPermissions.add()` which takes 4 arguments

  - The express app
  - The path you want to match
  - The boolean/object/function
  - True/False should this be wrapped in a promise (defaults to false)

Examples of all the permission types are below:

```javascript
//Allways allow requests to /
ExpressPermissions.add(app, '/', true)
//Allow access to /admin if response.local.current_user.admin == 1
ExpressPermissions.add(app, '/admin', {current_user: {admin: 1}})
//Allow access to /admin/reboot if the supplied function returns true
ExpressPermissions.add(app, '/admin/reboot', function (req, res){
  return (req.ip == '127.0.0.1')
})

//Allow access if this promise resolves true
ExpressPermissions.add(app, '/project/:id/edit', function (req, res, resolve, reject){
  MyDatabase.query("SELECT * FROM `projects` WHERE `id` = '" + req.params.id + "' LIMIT 1").then(function(project){
      resolve(project.editable)
  })
}, true)
```

Permission checks travel upwards, in this example a request for `/admin/index` would see no permission itself and then try `/admin`. Due to this it is highly reccomended that you define something for `/` otherwise you may end up with routes that have no permissions.

### Handling Error 403s

By default express-permissions ends the response preventing it from traveling any further this leaves the user with an empty reply which isn't really any good.

If you define `app.permissionDenied` it will be called when an error 403 is triggered instead of ending the response.

`app.permissionDenied` needs to take 2 arguments `req` and `res` and should work like any other express method.
