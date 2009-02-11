package pl.maliboo.ftp
{
	import flash.events.EventDispatcher;
	
	import pl.maliboo.ftp.events.FTPCommandEvent;
	
	[Event(name="reply", 		type="maliboo.ftp.events.FTPCommandEvent")]
	
	public class FTPCommand extends EventDispatcher
	{
		private  static const ARGS_SEPARATOR:String = " ";
		
		private var _name:String;
		private var _args:Array;
		private var _reply:FTPReply;
		
		public function FTPCommand(name:String, args:Array=null)
		{
			_name = name;
			_args = args? args : [];
		}
		
		public function set reply(reply:FTPReply):void
		{
			_reply = reply;
			dispatchEvent(new FTPCommandEvent(FTPCommandEvent.REPLY, reply, this));
		}
		
		public function get reply():FTPReply
		{
			return _reply;
		}
		
		public function get name():String
		{
			return _name;
		}
		
		public function get args():Array
		{
			return _args.splice();
		}
		
		public function get rawBody():String
		{
			return name + ARGS_SEPARATOR + _args.join(ARGS_SEPARATOR);
		}
		
		public function clone():FTPCommand
		{
			return new FTPCommand(name, args);
		}
	}
}