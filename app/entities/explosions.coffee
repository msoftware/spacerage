class Explosions extends PIXI.Container
  update: ->
    for explosion, i in @children by -1
      if explosion.finished
        @removeChildAt(i)
      else
        explosion.update()

module.exports = Explosions
