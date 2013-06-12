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
    # where the scroller was in the last animation frame
    @lastY       = iscroll.startY      or 0
    # marks the last position where blocks were moved
    @marker      = iscroll.startY      or 0
    @bufferSize  = options.bufferSize  or 5  # in blocks
    # size of a block in cells
    @blockSize   = options.blockSize   or @iscroll.scroller.children[0].children.length
    @poolSize    = @iscroll.scroller.children.length
    @blockHeight = @iscroll.scroller.children[0].clientHeight
    @poolHeight  = @poolSize * @blockHeight
    @availablePoolSize = @poolSize - 2*@bufferSize

    # listen for all scroll events (move & animate), require "probe"
    iscroll.on 'scroll', @_reuseCells

  _reuseCells: =>

    # determine direction b/c iscroll reports false directionY sometimes which
    # happens because it calculates deltaY false sometimes
    @direction =
      if @iscroll.y is @lastY
        @direction or -1
      else if @iscroll.y > @lastY
        -1
      else
        1
    @lastY = @iscroll.y

    # flip marker is direction has changed
    if (@marker > @iscroll.y and @direction is -1) or (@marker < @iscroll.y and @direction is 1)
      # console.log ">>> marker flipped: direction: #{@direction}, marker before flip: #{@marker}"
      @marker = @marker + 2*(@iscroll.y - @marker)

    # calculate delta w/o buffer
    delta = @iscroll.y - @marker
    delta = Math.abs(delta)-@bufferSize*@blockHeight
    blocksToMove = Math.floor (delta / @blockHeight)
    return if blocksToMove <= 0

    # console.log "marker: #{@marker}"
    # console.log "iscroll.y: #{@iscroll.y}"
    # console.log "blocksToMove: #{blocksToMove}"

    # update blocksMoved to accomodate for "skipping" entire poolsSizes
    # @blocksMoved += Math.floor (blocksToMove / @poolSize)
    if blocksToMove > @availablePoolSize
      # TODO: do not rerender all cells immediatelly when we move all blocks
      # but in batches or frames will be dropped
      @blocksMoved += blocksToMove - @availablePoolSize
      @marker += -@direction * (blocksToMove - @availablePoolSize) * @blockHeight
      # console.log "more blocksToMove than @availablePoolSize, updating @blocksMoved to #{@blocksMoved}, marker #{@marker}"
      blocksToMove = @availablePoolSize

    blocks = @_findBlocksToMove blocksToMove
    # console.log "blocks", blocks
    @_translateBlocks blocks

    # console.log "marker after translate: #{@marker}"


  # translates an array of block elements and updates values accordingly
  _translateBlocks: (blocks) ->
    for blockEl in blocks
      @_translateYBlockWithIndicesToPosition blockEl, @_calculateIndices(), @_calculatePosition()
      @blocksMoved += @direction
      @marker += -@direction * @blockHeight

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
    if @direction is 1
      poolsMoved = Math.floor (@blocksMoved * @blockHeight) / @poolHeight
      # console.log "calculated position: #{(poolsMoved + @direction) * @poolHeight}; for block #{@blocksMoved}"
      return (poolsMoved + @direction) * @poolHeight
    else
      poolsMoved = Math.floor ((@blocksMoved-1) * @blockHeight) / @poolHeight
      # console.log "calculated position: #{poolsMoved * @poolHeight}; for block #{@blocksMoved}"
      return poolsMoved * @poolHeight

  # Translate a block of cells to position and emit an event to reuse block
  # for a range of indices.
  _translateYBlockWithIndicesToPosition: (blockEl, indices, position) ->
    blockEl.style[@iscroll.utils.style.transform]='translateY('+position+'px)'
    # console.log ">>>> block moved:", blockEl
    # fire event so user can change the content of the block's cells.
    @_execEvent 'reuseBlockWithCellIndices', blockEl, indices

window.Infiniscroll = Infiniscroll