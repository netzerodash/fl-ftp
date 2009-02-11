package pl.maliboo.ftp
{
	public class FTPResponse
	{
		private var _code:int;
		private var _rawBody:String;
		
		public function FTPResponse(rawBody:String)
		{
			var lines:Array = rawBody.match(/^.+/gm);
			if (rawBody.charAt(3) == "-")
			{
				var lastLine:String = lines[lines.length-1];
				var has4:Boolean = lastLine.length >= 4;
				var isEndLine:Boolean = lastLine.charAt(3) != "-";
				var hasNaN:Boolean = isNaN(Number(lastLine.charAt(0)));
				if (!lastLine && !isEndLine && hasNaN)
					throw new ArgumentError("Body is malformed!");
			}
			
			_rawBody = rawBody;
			_code = parseInt(_rawBody.substr(0, 3));
		}
		
		public function get code():int
		{
			return _code;
		}
		
		public function get rawBody():String
		{
			return _rawBody;
		}
		
		public function get multiline():Boolean
		{
			return rawBody.charAt(3) == "-";
		}
		
		public function clone():FTPResponse
		{
			return new FTPResponse(rawBody);
		}
	}
}