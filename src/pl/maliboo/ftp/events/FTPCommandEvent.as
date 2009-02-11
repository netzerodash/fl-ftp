package pl.maliboo.ftp.events
{
	import flash.events.Event;
	
	import pl.maliboo.ftp.FTPCommand;
	import pl.maliboo.ftp.FTPResponse;
	
	public class FTPCommandEvent extends Event
	{
		public static const RESPONSE:String = "response";
		public static const COMMAND:String = "command";
		
		private var _response:FTPResponse;
		private var _command:*;
		
		public function FTPCommandEvent(type:String, response:FTPResponse=null, command:*=null)
		{
			super(type);
			_response = response;
			_command = command;
		}
		
		public function get command():*
		{
			return _command;
		}

		public function get response():FTPResponse
		{
			return _response;
		}
		
		override public function clone():Event
		{
			return new FTPCommandEvent(type, response, command);
		}
	}
}