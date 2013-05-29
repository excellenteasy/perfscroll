# Depends on IScroll being the iscroll-probe.js version.
class Infiniscroll

  # borrowing events from IScroll
  _execEvent: IScroll::_execEvent
  on: IScroll::on
  _events: {}

  constructor: (iscroll) ->
    # force options, just to be save. We can't use transition, because we need
    # request animation frame loop. This is implicitly done by probeType 3.
    @iscroll = iscroll
    options = iscroll.options
    options.probeType = 3

    # create namespace for infiniscroll data and setup defaults
    @blocksMoved = 0
    @lastY       = iscroll.startY      or 0
    @bufferSize  = options.bufferSize  or 2  # in blocks
    @blockSize   = options.blockSize   or 10 # in cells
    @poolSize    = @iscroll.scroller.children.length
    @blockHeight = @iscroll.scroller.children[0].clientHeight
    @poolHeight  = @poolSize * @blockHeight
    @availablePoolSize = @poolSize - 2*@bufferSize

    # listen for all scroll events (move & animate), require "probe"
    iscroll.on 'scroll', @_reuseCells

  _reuseCells: =>

    @direction = @iscroll.directionY
    if @direction is 0
      @direction = if @iscroll.y < @lastY then 1 else -1

    # flip lastY is direction has changed
    if (@lastY > @iscroll.y and @direction is -1) or (@lastY < @iscroll.y and @direction is 1)
      @lastY = @lastY + 2*(@iscroll.y - @lastY)
      console.log ">>> lastY flipped!"

    # calculate delta w/o buffer
    delta = @iscroll.y - @lastY
    delta = Math.abs(delta)-@bufferSize*@blockHeight
    blocksToMove = Math.floor (delta / @blockHeight)
    return if blocksToMove <= 0

    console.log "lastY: #{@lastY}"
    console.log "iscroll.y: #{@iscroll.y}"
    console.log "blocksToMove: #{blocksToMove}"

    # update blocksMoved to accomodate for "skipping" entire poolsSizes
    # @blocksMoved += Math.floor (blocksToMove / @poolSize)
    if blocksToMove > @availablePoolSize
      @blocksMoved += blocksToMove - @availablePoolSize
      @lastY += -@direction * (blocksToMove - @availablePoolSize) * @blockHeight
      console.log "more blocksToMove than @availablePoolSize, updating @blocksMoved to #{@blocksMoved}, lastY #{@lastY}"
      blocksToMove = @availablePoolSize

    blocks = @_findBlocksToMove blocksToMove
    console.log "blocks", blocks
    @_translateBlocks blocks

    console.log "lastY after translate: #{@lastY}"


  # translates an array of block elements and updates values accordingly
  _translateBlocks: (blocks) ->
    for blockEl in blocks
      @_translateYBlockWithIndicesToPosition blockEl, @_calculateIndices(), @_calculatePosition()
      @blocksMoved += @direction
      @lastY += -@direction * @blockHeight

  # returns an array of DOM elements to be move in that order
  # @blocksToMove [Number] the number of blocks to be moved
  _findBlocksToMove: (blocksToMove) ->
    blocks = []
    relativeMoved = @blocksMoved % @poolSize
    if @direction is 1
      if relativeMoved + blocksToMove >= @poolSize
        for i in [relativeMoved...@poolSize]
          blocks.push @iscroll.scroller.children[i]
        remaining = blocksToMove - (@poolSize-relativeMoved)

        for i in [0...remaining]
          blocks.push @iscroll.scroller.children[i]
      else
          blocks.push @iscroll.scroller.children[i] for i in [relativeMoved...(relativeMoved+blocksToMove)]
    else
      if relativeMoved is 0 then relativeMoved = @poolSize
      if relativeMoved - blocksToMove < 0
        for i in [relativeMoved-1...0]
          blocks.push @iscroll.scroller.children[i]
        remaining = blocksToMove - relativeMoved

        for i in [@poolSize-1...@poolSize-remaining]
          blocks.push @iscroll.scroller.children[i]
      else
        for i in [relativeMoved-1..(relativeMoved-blocksToMove)]
          blocks.push @iscroll.scroller.children[i]
    if blocks.length is 0 then debugger
    return blocks

  # Calculates indices for cells in a block to be moved
  # @param direction [Number] either 1 to move to the bottom or -1 to move to the top
  _calculateIndices: ->
    poolsMoved = Math.floor (@blocksMoved / @poolSize)
    start = ((poolsMoved + @direction) * @poolSize + (@blocksMoved % @poolSize)) * @blockSize
    end   = start + @blockSize
    return [start...end]

  # Calculates position to move block to
  # @param direction [Number] either 1 to move to the bottom or -1 to move to the top
  _calculatePosition: ->
    poolsMoved = Math.floor (@blocksMoved * @blockHeight) / @poolHeight
    console.log "calculated position: #{(poolsMoved + @direction) * @poolHeight}"
    if @direction is 1
      return (poolsMoved + @direction) * @poolHeight
    else
      return poolsMoved * @poolHeight

  # Translate a block of cells to position and emit an event to reuse block
  # for a range of indices.
  _translateYBlockWithIndicesToPosition: (blockEl, indices, position) ->
    blockEl.style[@iscroll.utils.style.transform]='translateY('+position+'px)'
    console.log ">>>> block moved:", blockEl
    # fire event so user can change the content of the block's cells.
    @_execEvent 'reuseBlockWithCellIndices', blockEl, indices

window.Infiniscroll = Infiniscroll