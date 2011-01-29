package com.wakuworks.idna 
{
	import flash.utils.*;
	import com.wakuworks.idna.*;
	import com.wakuworks.net.URLParser;
	
	/**
	 * PunycodeとUnicodeとの間で変換を行います。
	 * 
	 * @author  Kazunori Ninomiya
	 * @version 0.1.0
	 * @version Project 0.1.0
	 * @since   0.1.0
	 * @license http://www.opensource.org/licenses/mit-license.php The MIT License
	 * @see     <a href="http://www.jdna.jp/survey/rfc/rfc3490j.html">RFC3490</a>
	 */
	public final class IDNA
	{
		/** Punycodeに付加する接頭辞（{@value}）です。 */
		public  static const ACE_PREFIX:String = "xn--";
		private static var _nameprep:Nameprep = Nameprep.getInstance();
		
		/**
		 * コンストラクタ
		 * 
		 * @throws Error new演算子によるインスタンスの生成が行われた場合
		 */
		public function IDNA()
		{
			throw new Error("インスタンスを生成する事は出来ません。");
		}
		
		/**
		 * 国際化ドメイン名へ変換します。
		 * 
		 * 指定されたURL、もしくはメールアドレスを解析し、必要に応じて変換を行います。
		 * 
		 * @param 　input 変換対象の文字列
		 * @return　変換後の文字列
		 * @throws Error Punycodeへの変換に失敗した場合
		 */
		public static function encode(input:String):String
		{
			var parser:URLParser = new URLParser(input);
			try {
				if (parser.host) {
					parser.host = _encode(parser.host);
				}
				if (parser.user) {
					parser.user = _encode(parser.user);
				}
				if (parser.pass) {
					parser.pass = _encode(parser.pass);
				}
				if (parser.path) {
					parser.path = parser.path.replace(/([^\/]+)/g, _escape);
				}
				if (parser.query) {
					parser.query = parser.query.replace(/([^&=]+)/g, _escape);
				}
				if (parser.fragment) {
					parser.fragment = escapeMultiByte(parser.fragment);
				}
			}
			catch (e:Error) {
				throw e;
			}
			return parser.toString();
		}
		
		/**
		 * 通常のドメイン名に変換します。
		 * 
		 * 指定されたURL、もしくはメールアドレスを解析し、必要に応じて変換を行います。
		 * 
		 * @param  input 変換対象の文字列
		 * @return　変換後の文字列
		 * @throws Error 通常文字列への変換に失敗した場合
		 */
		public static function decode(input:String):String
		{
			var parser:URLParser = new URLParser(input);
			try {
				if (parser.host) {
					parser.host = _decode(parser.host);
				}
				if (parser.user) {
					parser.user = _decode(parser.user);
				}
				if (parser.pass) {
					parser.pass = _decode(parser.pass);
				}
				if (parser.path) {
					parser.path = unescapeMultiByte(parser.path);
				}
				if (parser.query) {
					parser.query = unescapeMultiByte(parser.query);
				}
				if (parser.fragment) {
					parser.fragment = unescapeMultiByte(parser.fragment);
				}
			}
			catch (e:Error) {
				throw e;
			}
			return parser.toString();
		}
		
		//----------------------------------------------------------------
		// 説明：  UnicodeからPunycodeへ変換し、その値を返す。
		// 引数：  Unicode文字列
		// 戻り値： Punycode文字列
		// 例外：  変換に失敗した場合
		//----------------------------------------------------------------
		private static function _encode(input:String):String
		{
			var str   :String = input.replace(/\u3002|\uFF0E|\uFF61/g, String.fromCharCode("0x2E"));
			var part  :Array  = str.split(/\x2E|\x2F|\x3A|\x3F|\x40/g);
			var length:uint   = part.length;
			for (var i:uint = 0; i < length; i++) {
				try {
					part[i] = _encodePunycode(part[i]);
				}
				catch (e:Error) {
					throw e;
				}
			}
			return part.join(".");
		}
		
		//----------------------------------------------------------------
		// 説明：  PunycodeからUnicodeへ変換し、その値を返す。
		// 引数：  Punycode文字列
		// 戻り値： Unicode文字列
		// 例外：  変換に失敗した場合
		//----------------------------------------------------------------
		private static function _decode(input:String):String
		{
			var re      :RegExp = new RegExp("^" + ACE_PREFIX);
			var pcLength:uint   = ACE_PREFIX.length;
			var part    :Array  = input.split(/\x2E|\x2F|\x3A|\x3F|\x40/g);
			var length  :uint   = part.length;
			for (var i:uint = 0, str:String; i < length; i++) {
				if (part[i].match(re)) {
					try {
						str = part[i].substr(pcLength);
						part[i] = Punycode.decode(str);
					}
					catch (e:Error) {
						throw e;
					}
				}
			}
			return part.join(".");
		}
		
		//----------------------------------------------------------------
		// 説明：  Punycodeに変換し、その値を返します。
		// 引数：  変換対象の文字列
		// 戻り値： 変換後の文字列
		// 例外：  既にPunycodeである場合
		//       変換に失敗した場合
		//----------------------------------------------------------------
		private static function _encodePunycode(input:String):String
		{
			var re:RegExp = new RegExp("^" + ACE_PREFIX);
			if (input.match(re)) {
				throw new Error("既にPunycodeに変換されています。");
			}
			
			var length:uint = input.length;
			for (var i:uint = 0; i < length; i++) {
				if (0x7a < input.charCodeAt(i)) {
					try {
						_nameprep.checkProhibited(input);
						input = _nameprep.mapping(input);
						return ACE_PREFIX + Punycode.encode(input);
					}
					catch (e:Error) {
						throw e;
					}
				}
			}
			return input;
		}
		
		//----------------------------------------------------------------
		// 説明：  System.useCodePageを基に文字列をエンコードし、その値を返す。
		// 戻り値： エンコード後の文字列
		//----------------------------------------------------------------
		private static function _escape():String
		{
			return escapeMultiByte(arguments[0]);
		}
	}
}