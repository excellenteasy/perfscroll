(function() {
  var Infiniscroll,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Infiniscroll = (function() {
    Infiniscroll.prototype._execEvent = IScroll.prototype._execEvent;

    Infiniscroll.prototype.on = IScroll.prototype.on;

    Infiniscroll.prototype._events = {};

    function Infiniscroll(iscroll) {
      this._reuseCells = __bind(this._reuseCells, this);
      var options;

      this.iscroll = iscroll;
      options = iscroll.options;
      options.probeType = 3;
      this.blocksMoved = 0;
      this.lastY = iscroll.startY || 0;
      this.bufferSize = options.bufferSize || 2;
      this.blockSize = options.blockSize || 10;
      this.poolSize = this.iscroll.scroller.children.length;
      this.blockHeight = this.iscroll.scroller.children[0].clientHeight;
      this.poolHeight = this.poolSize * this.blockHeight;
      this.availablePoolSize = this.poolSize - 2 * this.bufferSize;
      iscroll.on('scroll', this._reuseCells);
    }

    Infiniscroll.prototype._reuseCells = function() {
      var blocks, blocksToMove, delta;

      this.direction = this.iscroll.directionY;
      if (this.direction === 0) {
        this.direction = this.iscroll.y < this.lastY ? 1 : -1;
      }
      if ((this.lastY > this.iscroll.y && this.direction === -1) || (this.lastY < this.iscroll.y && this.direction === 1)) {
        this.lastY = this.lastY + 2 * (this.iscroll.y - this.lastY);
        console.log(">>> lastY flipped!");
      }
      delta = this.iscroll.y - this.lastY;
      delta = Math.abs(delta) - this.bufferSize * this.blockHeight;
      blocksToMove = Math.floor(delta / this.blockHeight);
      if (blocksToMove <= 0) {
        return;
      }
      console.log("lastY: " + this.lastY);
      console.log("iscroll.y: " + this.iscroll.y);
      console.log("blocksToMove: " + blocksToMove);
      if (blocksToMove > this.availablePoolSize) {
        this.blocksMoved += blocksToMove - this.availablePoolSize;
        this.lastY += -this.direction * (blocksToMove - this.availablePoolSize) * this.blockHeight;
        console.log("more blocksToMove than @availablePoolSize, updating @blocksMoved to " + this.blocksMoved + ", lastY " + this.lastY);
        blocksToMove = this.availablePoolSize;
      }
      blocks = this._findBlocksToMove(blocksToMove);
      console.log("blocks", blocks);
      this._translateBlocks(blocks);
      return console.log("lastY after translate: " + this.lastY);
    };

    Infiniscroll.prototype._translateBlocks = function(blocks) {
      var blockEl, _i, _len, _results;

      _results = [];
      for (_i = 0, _len = blocks.length; _i < _len; _i++) {
        blockEl = blocks[_i];
        this._translateYBlockWithIndicesToPosition(blockEl, this._calculateIndices(), this._calculatePosition());
        this.blocksMoved += this.direction;
        _results.push(this.lastY += -this.direction * this.blockHeight);
      }
      return _results;
    };

    Infiniscroll.prototype._findBlocksToMove = function(blocksToMove) {
      var blocks, i, relativeMoved, remaining, _i, _j, _k, _l, _m, _n, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6;

      blocks = [];
      relativeMoved = this.blocksMoved % this.poolSize;
      if (this.direction === 1) {
        if (relativeMoved + blocksToMove >= this.poolSize) {
          for (i = _i = relativeMoved, _ref = this.poolSize; relativeMoved <= _ref ? _i < _ref : _i > _ref; i = relativeMoved <= _ref ? ++_i : --_i) {
            blocks.push(this.iscroll.scroller.children[i]);
          }
          remaining = blocksToMove - (this.poolSize - relativeMoved);
          for (i = _j = 0; 0 <= remaining ? _j < remaining : _j > remaining; i = 0 <= remaining ? ++_j : --_j) {
            blocks.push(this.iscroll.scroller.children[i]);
          }
        } else {
          for (i = _k = relativeMoved, _ref1 = relativeMoved + blocksToMove; relativeMoved <= _ref1 ? _k < _ref1 : _k > _ref1; i = relativeMoved <= _ref1 ? ++_k : --_k) {
            blocks.push(this.iscroll.scroller.children[i]);
          }
        }
      } else {
        if (relativeMoved === 0) {
          relativeMoved = this.poolSize;
        }
        if (relativeMoved - blocksToMove < 0) {
          for (i = _l = _ref2 = relativeMoved - 1; _ref2 <= 0 ? _l < 0 : _l > 0; i = _ref2 <= 0 ? ++_l : --_l) {
            blocks.push(this.iscroll.scroller.children[i]);
          }
          remaining = blocksToMove - relativeMoved;
          for (i = _m = _ref3 = this.poolSize - 1, _ref4 = this.poolSize - remaining; _ref3 <= _ref4 ? _m < _ref4 : _m > _ref4; i = _ref3 <= _ref4 ? ++_m : --_m) {
            blocks.push(this.iscroll.scroller.children[i]);
          }
        } else {
          for (i = _n = _ref5 = relativeMoved - 1, _ref6 = relativeMoved - blocksToMove; _ref5 <= _ref6 ? _n <= _ref6 : _n >= _ref6; i = _ref5 <= _ref6 ? ++_n : --_n) {
            blocks.push(this.iscroll.scroller.children[i]);
          }
        }
      }
      if (blocks.length === 0) {
        debugger;
      }
      return blocks;
    };

    Infiniscroll.prototype._calculateIndices = function() {
      var end, poolsMoved, start, _i, _results;

      poolsMoved = Math.floor(this.blocksMoved / this.poolSize);
      start = ((poolsMoved + this.direction) * this.poolSize + (this.blocksMoved % this.poolSize)) * this.blockSize;
      end = start + this.blockSize;
      return (function() {
        _results = [];
        for (var _i = start; start <= end ? _i < end : _i > end; start <= end ? _i++ : _i--){ _results.push(_i); }
        return _results;
      }).apply(this);
    };

    Infiniscroll.prototype._calculatePosition = function() {
      var poolsMoved;

      poolsMoved = Math.floor((this.blocksMoved * this.blockHeight) / this.poolHeight);
      console.log("calculated position: " + ((poolsMoved + this.direction) * this.poolHeight));
      if (this.direction === 1) {
        return (poolsMoved + this.direction) * this.poolHeight;
      } else {
        return poolsMoved * this.poolHeight;
      }
    };

    Infiniscroll.prototype._translateYBlockWithIndicesToPosition = function(blockEl, indices, position) {
      blockEl.style[this.iscroll.utils.style.transform] = 'translateY(' + position + 'px)';
      console.log(">>>> block moved:", blockEl);
      return this._execEvent('reuseBlockWithCellIndices', blockEl, indices);
    };

    return Infiniscroll;

  })();

  window.Infiniscroll = Infiniscroll;

}).call(this);
