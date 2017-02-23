Camera = require "../camera"
Timer = require "../timer"
Joystick = require "../joystick"
Vec2 = require "../vec2"
Background = require "../entities/background"
Ship = require "../entities/ship"
Enemy = require "../entities/enemy"
Explosion = require "../entities/explosion"
Explosions = require "../entities/explosions"
HasVelocity = require "../components/has_velocity"
CanUpdate = require "../components/can_update"


module.exports = class GameScene extends PIXI.Container
  constructor: ->
    super()

    # load sounds
    @fireSound = new Howl
      src: ['/sounds/laser.wav']
      volume: 0.3

    @explosionSound = new Howl
      src: ['/sounds/explosion.wav']
      volume: 0.4

    # start stupid music
    @music = new Howl
      src: ['/sounds/theme.mp3']
      autoplay: true
      loop: true
      volume: 1

    # set up timers
    @fireTimer = new Timer

    # set up world
    @world = new PIXI.Container
    @addChild @world

    # set up some tools
    @camera = new Camera(@world)
    @joystick = new Joystick

    # set up entities
    @ship = new Ship
    @background = new Background(@ship)

    # set up containers
    @bullets = new PIXI.Container
    @enemyBullets = new PIXI.Container
    @enemies = new PIXI.Container
    @explosions = new Explosions

    # set up debug text
    @debug = new PIXI.Text("moo", {fontFamily : 'Arial', fontSize: 24, fill : 0xff1010, align : 'center'})
    @debug.x = 10
    @debug.y = 10

    # Add entities to our world stage
    @world.addChild @background
    @world.addChild @ship
    @world.addChild @bullets
    @world.addChild @enemyBullets
    @world.addChild @enemies
    @world.addChild @explosions
    # @addChild @debug

    # Start enemy spawner
    @scheduleSpawnEnemy()

    # Set up some global key events
    key 'm', =>
      if @music.playing()
        @music.pause()
      else
        @music.play()


  update: ->
    now = Date.now()

    @debug.text = "moo"

    @joystick.update()
    @camera.lookAt(@ship)
    @ship.update()
    @background.update()

    @handleInput()

    # update enemies
    for enemy, i in @enemies.children by -1
      enemy.update()

    # update bullets
    for bullet, i in @bullets.children by -1
      # check bullet lifetime
      if now > bullet.created + 1000
        @bullets.removeChildAt(i)
      else
        bullet.update()

        # check collisions
        for enemy, t in @enemies.children by -1
          distance = new Vec2(enemy.x, enemy.y).distance(new Vec2(bullet.x, bullet.y))

          if distance < 30
            # create an explosion for the enemy ship
            explosion = new Explosion()
            explosion.position = enemy.position
            @explosions.addChild(explosion)
            @explosionSound.play()

            # remove enemy and bullet
            @enemies.removeChildAt(t)
            @bullets.removeChildAt(i)

    # update enemy bullets
    for bullet, i in @enemyBullets.children by -1
      # check bullet lifetime
      if now > bullet.created + 3000
        @enemyBullets.removeChildAt(i)
      else
        bullet.update()

        distance = new Vec2(@ship.x, @ship.y).distance(bullet)
        if distance < 50
          # apply a bit of impact to the player ship
          @ship.velocity = @ship.velocity.add(bullet.velocity.scale(0.2))
          @ship.accelerateRotation(-0.01 + Math.random() * 0.02)

          # remove bullet
          @enemyBullets.removeChildAt(i)



    # update explosions
    @explosions.update()

  handleInput: ->
    @ship.accelerateForward(0.8 * @joystick.y)
    @ship.accelerateRotation(0.005 * @joystick.x)

    if @joystick.keyIsPressed("space")
      @fireTimer.cooldown 100, =>
        @fireSound.play()
        @bullets.addChild @makeBullet(-43, -4)
        @bullets.addChild @makeBullet(43, -4)

    if @joystick.keyIsPressed("e")
      @spawnEnemy()

  makeBullet: (offsetX = 0, offsetY = 0) ->
    bullet = new PIXI.Graphics
    bullet.beginFill(0xFFFFFF, 0.1);
    bullet.drawCircle(0, 0, 15);
    bullet.beginFill(0xFFFFFF, 0.4);
    bullet.drawCircle(0, 0, 8);
    bullet.beginFill(0xFFFFFF, 1);
    bullet.drawCircle(0, 0, 5);

    # set up initial position and movement
    CanUpdate(bullet)
    HasVelocity(bullet)
    bullet.position = new Vec2(@ship.x, @ship.y).add(new Vec2(offsetX, offsetY).rotate(@ship.rotation))
    bullet.rotation = @ship.rotation
    bullet.drag = 1
    bullet.accelerateForward(20)

    # set up ticker to remove bullet
    bullet.created = Date.now()

    bullet


  spawnEnemy: ->
    @enemies.addChild @makeEnemy()

  scheduleSpawnEnemy: ->
    setTimeout =>
      if @enemies.children.length < 40
        @spawnEnemy()

      @scheduleSpawnEnemy()
    , 500

  makeEnemy: ->
    enemy = new Enemy(@ship, @fireEnemyBullet)

    enemy.position = Vec2.up
      .scale(1000 + Math.random() * 1000)
      .rotate(Math.random() * 2 * Math.PI)
      .add(new Vec2(@ship.x, @ship.y))

    enemy.rotation = Math.random() * 2 * Math.PI

    enemy

  fireEnemyBullet: (enemy) =>
    # @fireSound.play()

    bullet = new PIXI.Graphics
    bullet.beginFill(0xFF0000, 0.5);
    bullet.drawCircle(0, 0, 6);
    bullet.beginFill(0xFF0000, 1);
    bullet.drawCircle(0, 0, 3);

    # set up initial position and movement
    CanUpdate(bullet)
    HasVelocity(bullet)
    bullet.position = new Vec2(enemy.x, enemy.y)
    bullet.rotation = enemy.rotation
    bullet.drag = 1
    bullet.accelerateForward(10)

    # set up ticker to remove bullet
    bullet.created = Date.now()

    @enemyBullets.addChild bullet
