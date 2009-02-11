package pl.maliboo.ftp.events
{
	import flash.events.Event;
	
	import pl.maliboo.ftp.FTPCommand;
	import pl.maliboo.ftp.FTPReply;
	
	public class FTPCommandEvent extends Event
	{
		public static const REPLY:String = "reply";
		public static const COMMAND:String = "command";
		
		private var _reply:FTPReply;
		private var _command:FTPCommand;
		
		public function FTPCommandEvent(type:String, reply:FTPReply=null, command:FTPCommand=null)
		{
			super(type);
			_reply = reply;
			_command = command;
		}
		
		public function get command():FTPCommand
		{
			return _command;
		}
		
		public function get reply():FTPReply
		{
			return _reply;
		}
		
		override public function clone():Event
		{
			return new FTPCommandEvent(type, reply, command);
		}
	}
}