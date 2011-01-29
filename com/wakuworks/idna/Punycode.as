package com.wakuworks.idna 
{
	/**
	 * ASCII文字列に変換します。
	 * 
	 * @author  Kazunori Ninomiya
	 * @version 0.1.0
	 * @version Project 0.1.0
	 * @since   0.1.0
	 * @license http://www.opensource.org/licenses/mit-license.php The MIT License
	 * @see     <a href="http://www.jdna.jp/survey/rfc/rfc3492j.html">RFC3492</a>
	 */
	public final class Punycode
	{
		private static const BASE        :uint = 36;
		private static const TMIN        :uint = 1;
		private static const TMAX        :uint = 26;
		private static const SKEW        :uint = 38;
		private static const DAMP        :uint = 700;
		private static const INITIAL_BIAS:uint = 72;
		private static const INITIAL_N   :uint = 0x80;
		private static const DELIMITER   :uint = 0x2D;
		private static const MAXINT      :uint = 0x7fffffff;
		
		/**
		 * コンストラクタ
		 * 
		 * @throws Error new演算子によるインスタンスの生成が行われた場合
		 */
		public function Punycode()
		{
			throw new Error("インスタンスを生成する事は出来ません。");
		}
		
		/**
		 * 文字列をPunycodeへ変換します。
		 * 
		 * @param  input 対象文字列
		 * @return 変換後の文字列
		 * @throws Error 不適切な文字列が引き渡された場合
		 */
		public static function encode(input:String):String
		{
			var n       :uint = INITIAL_N;
			var delta   :int  = 0;
			var out     :uint = 0
			var bias    :uint = INITIAL_BIAS;
			var i       :uint = 0;
			var m       :uint = 0;
			var length  :uint = input.length;
			var input_v :Vector.<uint> = _splitString(input);
			var output  :Vector.<uint> = new Vector.<uint>();
			
			for (i = 0; i < length; i++) {
				if (_basic(input_v[i])) {
					output[out++] = input_v[i];
				}
			}
			
			var b:uint = output.length;
			if (b) {
				output[out++] = DELIMITER;
			}
			
			var h:uint = b;
			while (h < length) {
				for (m = MAXINT, i = 0; i < length; i++) {
					if (input_v[i] >= n && input_v[i] < m) {
						m = input_v[i];
					}
				}
				
				if (m - n > (MAXINT - delta) / (h + 1)) {
					throw new Error("overflow");
				}
				delta += (m - n) * (h + 1);
				n = m;
				
				for (i = 0; i < length; i++) {
					if (input_v[i] < n && ++delta == 0) {
						throw new Error("overflow");
					}
					if (input_v[i] == n) {
						var q:uint = delta;
						var d:uint = 0;
						var t:uint = 0;
						for (var k:uint = BASE; ; k += BASE) {
							t = k <= bias ? TMIN :
								bias + TMAX <= k ? TMAX : k - bias;
							if (q < t) {
								break;
							}
							d = _encodeDigit(t + (q - t) % (BASE - t));
							output[out++] = d;
							q = (q - t) / (BASE - t);
						}
						
						output[out++] = _encodeDigit(q);
						bias  = _adapt(delta, h + 1, h == b);
						delta = 0;
						h++;
					}
				}
				delta++;
				n++;
			}
			
			var result:String = "";
			
			var c:uint = 0;
			for (i = 0, length = output.length; i < length; i++) {
				c = output[i];
				if (c < 0 || 127 < c) {
					break;
				}
				result += String.fromCharCode(c);
			}
			return result;
		}
		
		/**
		 * Punycodeから通常の文字列に変換します。
		 * 
		 * @param  input 対象文字列
		 * @return 変換後の文字列
		 * @throws Error 不適切な文字列が引き渡された場合
		 */
		public static function decode(input:String):String
		{
			var n      :uint = INITIAL_N;
			var out    :uint = 0;
			var i      :uint = 0;
			var j      :uint = 0;
			var b      :uint = 0;
			var bias   :uint = INITIAL_BIAS;
			var input_v:Vector.<uint> = _splitString(input);
			var output :Vector.<uint> = new Vector.<uint>();
			var length :uint = input_v.length;
			
			for (i = 0, b = 0; i < length; i++) {
				if (input_v[i] == DELIMITER) {
					b = i;
				}
			}
			
			for (i = 0; i < b; i++) {
				if (!_basic(input_v[i])) {
					throw new Error("bad input");
				}
				output[out++] = input_v[i];
			}
			
			for (var inp:uint = b > 0 ? b + 1 : 0; inp < length; out++) {
				for (var oldj:uint = j, w:uint = 1, k:uint = BASE; ; k += BASE) {
					if (length <= inp) {
						throw new Error("bad input");
					}
					var digit:uint = _decodeDigit(input_v[inp++]);
					if (BASE <= digit) {
						throw new Error("bad input");
					}
					if ((MAXINT - j) / w < digit) {
						throw new Error("overflow");
					}
					j += digit * w;
					var t:uint = k <= bias ? TMIN :
								 bias + TMAX <= k ? TMAX : k - bias;
					if (digit < t) {
						break;
					}
					if (MAXINT / (BASE - t) < w) {
						throw new Error("overflow");
					}
					w *= (BASE - t);
				}
				
				bias = _adapt(j - oldj, out + 1, oldj == 0);
				oldj = j / (out + 1);
				
				if (MAXINT - n < oldj) {
					throw new Error("overflow");
				}
				n += oldj;
				j %= (out + 1);
				output.splice(j++, 0, n);
			}
			
			var result:String = "";
			
			length = output.length;
			for (i = 0; i < length; i++) {
				result += String.fromCharCode(output[i]);
			}
			return result;
		}
		
		private static function _basic(cp:uint):Boolean
		{
			return cp < 0x80;
		}
		
		private static function _splitString(str:String):Vector.<uint>
		{
			var v:Vector.<uint> = new Vector.<uint>();
			var length:uint = str.length;
			for (var i:uint = 0; i < length; i++) {
				v[i] = str.charCodeAt(i);
			}
			return v;
		}
		
		private static function _decodeDigit(cp:uint):uint
		{
			return cp - 48 < 10 ? cp - 22 : cp - 65 < 26 ? cp - 65 :
				   cp - 97 < 26 ? cp - 97 : BASE;
		}
		
		private static function _encodeDigit(d:uint):uint
		{
			return d < 26 ? d + 97 : d + 22;
		}
		
		private static function _adapt(delta:uint, numpoints:uint, firsttime:Boolean):uint
		{
			delta  = firsttime ? delta / DAMP : delta >> 1;
			delta += delta / numpoints;
			for (var k:uint = 0; (((BASE - TMIN) * TMAX) >> 1) < delta; k += BASE) {
				delta /= BASE - TMIN;
			}
			return k + (BASE - TMIN + 1) * delta / (delta + SKEW);
		}
	}
}