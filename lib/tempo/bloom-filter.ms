public class BloomFilter {
  function initialize(options) {
    this.m = options.m;
    this.k = options.k;
    this.buffer = new BUFFER_CLASSES[options.type || 'string'](this.m, options.threshold);
  }

  function add(string) {
    var newKey = true;
    foreach (var idx in this.getIndexes(string)) {
      if (!this.buffer.setBit(idx)) newKey = false;
    }
    return newKey;
  }

  function getIndexes(v) {
    var a = fnv_1a(v);
    var b = (a >>> 16) & 0xffff;
    var i = -1;
    var m = this.m;
    var k = this.k;
    var indexes = [];

    while (++i < k)  {
      var idx = (a + i * b) % m;
      if (idx < 0) idx += m;
      indexes.push(Math.abs((a + i * b) % m));
    }

    return indexes;
  }
}

public class DynamicBuffer {
  function initialize(m, threshold) {
    this.m = m;
    this.threshold = threshold || (m / 2);
    this.buffer = new HashBuffer();
    this.thresholdReached = false;
    this.bitsSet = 0;
  }

  function setBit(idx) {
    var set = this.buffer.setBit(idx);
    if (this.thresholdReached) return set;

    if (set) this.bitSet++;
    if (this.bitSet > this.threshold) {
      var newBuffer = new StringBuffer();
      foreach (var idx in this.buffer.getIndexes()) {
        newBuffer.setBit(idx);
      }
      this.buffer = newBuffer;
      this.thresholdReached = true;
    }

    return set;
  }
}

public class StringBuffer {
  function initialize(m) {
    var nBytes  = Math.ceil(m / 8);
    this.buffer = new Buffer(nBytes);
    this.m = m;
  }

  function setBit(idx) {
    var byteIdx    = idx / 8;
    var byteOffset = idx % 8;
    if (!(this.buffer[byteIdx] & (1 << byteOffset))) {
      this.buffer[byteIdx] |= 1 << byteOffset;
      return false;
    } else {
      return true;
    }
  }

  function testBit(idx) {
    var byteIdx    = idx / 8;
    var byteOffset = idx % 8;
    return this.buffer[byteIdx] & (1 << byteOffset);
  }

  function getIndexes() {
    var ret = [];
    var buffer = this.buffer;
    for (var i=0,len=buffer.length; i<len; i++) {
      var c = buffer[i];
      for (var j=0; j<8; j++) {
        if (c & (1 << j)) ret.push(i*8+j);
      }
    }
    return ret;
  }
}

public class HashBuffer {
  function initialize(m) {
    this.buffer = {};
    this.m = m;
  }

  function setBit(idx) {
    if (idx in this.buffer) return true;
    return this.buffer[idx] = null;
  }

  function testBit(idx) {
    return idx in this.buffer;
  }

  function getIndexes() {
    var ret = [];
    for (var k in this.buffer) ret.push(k);
    return ret;
  }
}


// Helper functions


// Fowler/Noll/Vo hashing.
function fnv_1a(v) {
  var n = v.length,
      a = 0x811c9dc5,
      c,
      d,
      i = -1;
  while (++i < n) {
    c = v.charCodeAt(i);
    if (d = c & 0xff000000) {
      a ^= d >> 24;
      a += (a << 1) + (a << 4) + (a << 7) + (a << 8) + (a << 24);
      a &= 0xffffffff;
    }
    if (d = c & 0xff0000) {
      a ^= d >> 16;
      a += (a << 1) + (a << 4) + (a << 7) + (a << 8) + (a << 24);
      a &= 0xffffffff;
    }
    if (d = c & 0xff00) {
      a ^= d >> 8;
      a += (a << 1) + (a << 4) + (a << 7) + (a << 8) + (a << 24);
      a &= 0xffffffff;
    }
    a ^= c & 0xff;
    a = add(a, (a << 1) + (a << 4) + (a << 7) + (a << 8) + (a << 24));
    a &= 0xffffffff;
  }
  // From http://home.comcast.net/~bretm/hash/6.html
  a += a << 13;
  a ^= a >> 7;
  a += a << 3;
  a ^= a >> 17;
  a += a << 5;
  return a;
}


// Addition modulo 32-bits.
function add(a, b) {
  var r = a + (b - 0xffffffff - 1);
  if (r > 0) return r;
  return a + b;
}

// One additional iteration of FNV, given a hash.
function fnv_1a_b(a) {
  a += (a << 1) + (a << 4) + (a << 7) + (a << 8) + (a << 24);
  a += a << 13;
  a ^= a >> 7;
  a += a << 3;
  a ^= a >> 17;
  a += a << 5;
  return a & 0xffffffff;
}

var CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz";
function randomString() {
  var n = 8;
  var randomstring  = '';
  for (var i=0; i<n; i++) {
    var rnum = Math.floor(Math.random() * CHARS.length);
    randomstring += CHARS.substring(rnum,rnum+1);
  }
  return randomstring;
}

var BUFFER_CLASSES = {
  dynamic: DynamicBuffer,
  string:  StringBuffer,
  hash:    HashBuffer
};


