package com.wakuworks.net
{
	/**
	 * URLを解析します。
	 * 
	 * URLParser is freely distributable under the terms of an MIT-style license.
	 * 
	 * The orignal code: https://code.poly9.com/trac/browser/urlparser/urlparser.js
	 * 
	 * http://poly9.com
	 * http://www.twinapex.com
	 * 
	 * @author  Kazunori Ninomiya
	 * @version 0.1.0
	 * @version Project 0.1.0
	 * @since   0.1.0
	 * @license http://www.opensource.org/licenses/mit-license.php The MIT License
	 * @see     <a href="http://snipplr.com/view/10139/urlparse--pythonlike-url-parser-and-manipulator/">PYTHON-LIKE URL PARSER AND MANIPULATOR</a>
	 */
	public class URLParser
	{
		private static const _fields:Object = {
			"scheme":   2,
			"host":     6,
			"port":     7,
			"user":     4,
			"pass":     5,
			"path":     8,
			"query":    9,
			"fragment": 10
		};
		private static const _regex:RegExp = /^((\w+):\/\/)?(([^:]*):?([^@]*)?@)?([^\/\?:]+):?(\d+)?(\/?[^\?#]+)?\??([^#]+)?#?([^#]*)/;
		
		/** スキーム（http(s), ftp, mailto, fileなど） */
		public var scheme:String;
		
		/** ホスト名 */
		public var host:String;
		
		/** 接続先ポート番号 */
		public var port:String;
		
		/** ホストに接続するときに使うユーザー名 */
		public var user:String;
		
		/** ユーザー名に対応するパスワード */
		public var pass:String;
		
		/** ホストに要求するパス */
		public var path:String;
		
		/** クエリ文字列 */
		public var query:String;
		
		/** ハッシュ */
		public var fragment:String;
		
		/** 各パラメータを結合した文字列を返します。 */
		public function get url():String { return _getURL(); }
		
		/** URLを設定し、同時に解析して各パラメータに値を渡します。 */
		public function set url(u:String):void { _parse(u); }
		
		/**
		 * インスタンスを生成します。
		 *
		 * @param url 解析したいURL
		 */
		public function URLParser(_url:String = "")
		{
			url = _url;
		}
		
		/**
		 * クエリを解析し、オブジェクトとして返します。
		 * 
		 * @return 各パラメータ・値を持ったオブジェクト
		 */
		public function get cgi():Object
		{
			var cgi:Object = null;
			if (query) {
				cgi = {};
				var qq    :Array = query.split(unescape("&"));
				var length:uint  = qq.length;
				for (var i:uint = 0, q:Array; i < length ;i++) {
					q = qq[i].split("=");
					cgi[q[0]] = (q.length == 2) ? q[1] : undefined;
				}
			}
			return cgi;
		}
		
		/**
		 * オブジェクトを文字列にして返します。
		 * 
		 * 各パラメータを結合し、URLにして返します。
		 * 
		 * @return URL
		 */
		public function toString():String
		{
			return _getURL();
		}
		
		//----------------------------------------------------------------
		// 説明：  初期化し、各パラメータの値を空にします。
		// 戻り値： なし
		//----------------------------------------------------------------
		private function _init():void
		{
			scheme   = "";
			host     = "";
			port     = "";
			user     = "";
			pass     = "";
			path     = "";
			query    = "";
			fragment = "";
		}
		
		//----------------------------------------------------------------
		// 説明：  引数のURLを解析します。
		// 引数：  URL形式の文字列
		// 戻り値： なし
		//----------------------------------------------------------------
		private function _parse(url:String):void
		{
			_init();
			
			if (url) {
				var r:Array = _regex.exec(url);
				if (r) {
					var value:String = "";
					for (var f:String in _fields) {
						value = r[_fields[f]];
						if (value) {
							this[f] = value;
						}
					}
				}
			}
		}
		
		//----------------------------------------------------------------
		// 説明：  各パラメータを結合し、URLにして返す。
		// 戻り値： URL形式の文字列
		//----------------------------------------------------------------
		private function _getURL():String
		{
			var s:String = "";
			if (scheme) {
				s += scheme + "://";
			}
			if (user) {
				s += user;
			}
			if (pass) {
				s += ":" + pass;
			}
			if (user || pass) {
				s += "@";
			}
			s += host;
			if (port) {
				s += ":" + port;
			}
			s += path;
			if (query) {
				s += "?" + query;
			}
			if (fragment) {
				s += "#" + fragment;
			}
			return s;
		}
	}
}