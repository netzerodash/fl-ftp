package pl.maliboo.ftp
{
	import pl.maliboo.ftp.rfc959.ReplyType;

	public class FTPReply
	{
		private var _code:int;
		private var _rawBody:String;
		
		public function FTPReply(rawBody:String)
		{
			if (!rawBody.match(/^\d{3}/))
				throw new ArgumentError("Body is malformed! Code not found!");
			var lines:Array = rawBody.match(/^.+/gm);
			if (rawBody.charAt(3) == "-")
			{
				if (lines.length == 1)
					throw new ArgumentError("Body is malformed! Expected to be multiline!");
				var lastLine:String = lines[lines.length-1];
				var tooShort:Boolean = lastLine.length < 4;
				var isContinueLine:Boolean = lastLine.charAt(3) == "-";
				var startsWithNonDigit:Boolean = lastLine.match(/^\d{1,3}[^-]/) == null;
				if (tooShort || isContinueLine || startsWithNonDigit)
					throw new ArgumentError("Body is malformed! Last line not found!");
			}
			else if (lines.length > 1)
				throw new ArgumentError("Body is malformed! Expected to be singleline!");
			
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
		
		public function clone():FTPReply
		{
			return new FTPReply(rawBody);
		}
		
		public function get type():int
		{
			return ReplyType.getType(code);
		}
		
		public function toString():String
		{
			return rawBody;
		}
	}
}