# Depends on IScroll being the iscroll-probe.js version.
class Infiniscroll

  constructor: (iscroll) ->
    # force options, just to be save. We can't use transition, because we need
    # request animation frame loop. This is implicitly done by probeType 3.
    @iscroll = iscroll
    options = iscroll.options
    options.probeType = 3

    # create namespace for infiniscroll data and setup defaults
    @infiniscroll =
      cellsMoved: 0
      # TODO: vanilla JS
      cellHeight: options.cellHeight or $(iscroll.scroller.children[0]).outerHeight()
      lastY: iscroll.startY or 0
      lastX: iscroll.startX or 0
      bufferSize: options.bufferSize or 50
      blockSize: options.blockSize or 25

    # listen for all scroll events (move & animate), require "probe"
    iscroll.on 'scroll', @_reuseCellsOnScroll

  # borrowing events from IScroll
  _execEvent: IScroll::_execEvent
  on: IScroll::on
  _events: {}

  _reuseCellsOnScroll: =>

    # calculate delta y before translating
    deltaY = @iscroll.y - @infiniscroll.lastY

    # calculate how many cells were translated out of wrapper
    # minus bufferSize
    height = @infiniscroll.cellHeight
    delta  = Math.abs(deltaY)-@infiniscroll.bufferSize
    if delta < 0 then delta = 0
    cellsToTranslate = Math.floor delta / height

    # check if we need to skip an entire poolsize worth of cells
    # This is the case when we scroll so fast that in one frame we exceed the
    # entire pool of elements
    poolSize = @iscroll.scroller.children.length
    if cellsToTranslate >= poolSize
      # move the entire pool i times where i is the number of pools skipped
      x = Math.floor(cellsToTranslate/poolSize)
      indices = [@infiniscroll.cellsMoved+(x-1)*poolSize...@infiniscroll.cellsMoved+x*poolSize]
      @_translateCells @iscroll.scroller.children, indices, x
      cellsToTranslate = cellsToTranslate % poolSize

    # only move cells if we have at least one block to move
    if cellsToTranslate > @infiniscroll.blockSize

      cells = []
      indices = []

      relativeMoved = @infiniscroll.cellsMoved % poolSize

      # edge case: if what we have moved so far plus the cells we are going to
      # move if greater that the total number of cells in the pool
      # we must use the last and first cells of pool
      # Note: 'first' and 'last' mean the node's position in the DOM, not where
      # they currently are visible.
      if cellsToTranslate + relativeMoved > poolSize

        # first, we move the last cells in the pool
        for i in [relativeMoved...poolSize]
          cells.push @iscroll.scroller.children[i]
          indices.push @infiniscroll.cellsMoved + i
        @_translateCells cells, indices

        # reset
        cells = []
        lastIndex = indices[indices.length-1]
        indices = []

        # now we move the rest of the cells from the beginning the pool
        for i in [0..cellsToTranslate-(poolSize-relativeMoved)]
          cells.push @iscroll.scroller.children[i]
          indices.push lastIndex + 1 + i

      # We have enough cells left before the end of the buffer, so we can
      # go on transforming cells.
      else
        for i in [relativeMoved...relativeMoved+cellsToTranslate]
          cells.push @iscroll.scroller.children[i]
          indices.push @infiniscroll.cellsMoved + i

      @_translateCells cells, indices

  # Translates a number of cells to the bottom of the buffer.
  # @param cells [Array] DOM nodes
  # @param indices [Array] map of indices corresponing to cells array
  # @pram factor [Number] how many times the poolsize is taken into account
  _translateCells: (cells, indices, factor=1) ->
    # determine cell height
    cellHeight = @infiniscroll.cellHeight
    poolSize = @iscroll.scroller.children.length
    timesMoved = Math.floor @infiniscroll.cellsMoved/poolSize+1
    #setTimeout =>
    for cell, i in cells
      cell.style[@iscroll.utils.style.transform]='translateY('+timesMoved*factor*poolSize*cellHeight+'px)'
      # fire event so user can change the content of the cell
      # index is the number of the cell in the application logic, so this can be
      # anything from 0 to the very last cell that can be scrolled to.
      do (cell) => @_execEvent 'reuseCellForIndex', cell, indices[i]
    #, 0

    @infiniscroll.cellsMoved += cells.length
    # reset lastY
    @infiniscroll.lastY -= cells.length * @infiniscroll.cellHeight

window.Infiniscroll = Infiniscroll