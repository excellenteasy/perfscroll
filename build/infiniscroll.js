(function() {
  var Infiniscroll,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Infiniscroll = (function() {
    function Infiniscroll(iscroll) {
      this._reuseCellsOnScroll = __bind(this._reuseCellsOnScroll, this);
      var options;

      this.iscroll = iscroll;
      options = iscroll.options;
      options.probeType = 3;
      this.infiniscroll = {
        cellsMoved: 0,
        cellHeight: options.cellHeight || $(iscroll.scroller.children[0]).outerHeight(),
        lastY: iscroll.startY || 0,
        lastX: iscroll.startX || 0,
        bufferSize: options.bufferSize || 50,
        blockSize: options.blockSize || 25
      };
      iscroll.on('scroll', this._reuseCellsOnScroll);
    }

    Infiniscroll.prototype._execEvent = IScroll.prototype._execEvent;

    Infiniscroll.prototype.on = IScroll.prototype.on;

    Infiniscroll.prototype._events = {};

    Infiniscroll.prototype._reuseCellsOnScroll = function() {
      var cells, cellsToTranslate, delta, deltaY, height, i, indices, lastIndex, poolSize, relativeMoved, x, _i, _j, _k, _l, _ref, _ref1, _ref2, _ref3, _results;

      deltaY = this.iscroll.y - this.infiniscroll.lastY;
      height = this.infiniscroll.cellHeight;
      delta = Math.abs(deltaY) - this.infiniscroll.bufferSize;
      if (delta < 0) {
        delta = 0;
      }
      cellsToTranslate = Math.floor(delta / height);
      poolSize = this.iscroll.scroller.children.length;
      if (cellsToTranslate >= poolSize) {
        x = Math.floor(cellsToTranslate / poolSize);
        indices = (function() {
          _results = [];
          for (var _i = _ref = this.infiniscroll.cellsMoved + (x - 1) * poolSize, _ref1 = this.infiniscroll.cellsMoved + x * poolSize; _ref <= _ref1 ? _i < _ref1 : _i > _ref1; _ref <= _ref1 ? _i++ : _i--){ _results.push(_i); }
          return _results;
        }).apply(this);
        this._translateCells(this.iscroll.scroller.children, indices, x);
        cellsToTranslate = cellsToTranslate % poolSize;
      }
      if (cellsToTranslate > this.infiniscroll.blockSize) {
        cells = [];
        indices = [];
        relativeMoved = this.infiniscroll.cellsMoved % poolSize;
        if (cellsToTranslate + relativeMoved > poolSize) {
          for (i = _j = relativeMoved; relativeMoved <= poolSize ? _j < poolSize : _j > poolSize; i = relativeMoved <= poolSize ? ++_j : --_j) {
            cells.push(this.iscroll.scroller.children[i]);
            indices.push(this.infiniscroll.cellsMoved + i);
          }
          this._translateCells(cells, indices);
          cells = [];
          lastIndex = indices[indices.length - 1];
          indices = [];
          for (i = _k = 0, _ref2 = cellsToTranslate - (poolSize - relativeMoved); 0 <= _ref2 ? _k <= _ref2 : _k >= _ref2; i = 0 <= _ref2 ? ++_k : --_k) {
            cells.push(this.iscroll.scroller.children[i]);
            indices.push(lastIndex + 1 + i);
          }
        } else {
          for (i = _l = relativeMoved, _ref3 = relativeMoved + cellsToTranslate; relativeMoved <= _ref3 ? _l < _ref3 : _l > _ref3; i = relativeMoved <= _ref3 ? ++_l : --_l) {
            cells.push(this.iscroll.scroller.children[i]);
            indices.push(this.infiniscroll.cellsMoved + i);
          }
        }
        return this._translateCells(cells, indices);
      }
    };

    Infiniscroll.prototype._translateCells = function(cells, indices, factor) {
      var cell, cellHeight, i, poolSize, timesMoved, _fn, _i, _len,
        _this = this;

      if (factor == null) {
        factor = 1;
      }
      cellHeight = this.infiniscroll.cellHeight;
      poolSize = this.iscroll.scroller.children.length;
      timesMoved = Math.floor(this.infiniscroll.cellsMoved / poolSize + 1);
      _fn = function(cell) {
        return _this._execEvent('reuseCellForIndex', cell, indices[i]);
      };
      for (i = _i = 0, _len = cells.length; _i < _len; i = ++_i) {
        cell = cells[i];
        cell.style[this.iscroll.utils.style.transform] = 'translateY(' + timesMoved * factor * poolSize * cellHeight + 'px)';
        _fn(cell);
      }
      this.infiniscroll.cellsMoved += cells.length;
      return this.infiniscroll.lastY -= cells.length * this.infiniscroll.cellHeight;
    };

    return Infiniscroll;

  })();

  window.Infiniscroll = Infiniscroll;

}).call(this);
