package pl.maliboo.ftp
{
	import flash.errors.IllegalOperationError;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	import pl.maliboo.ftp.events.FTPCommandEvent;
	import pl.maliboo.ftp.rfc959.ReplyType;
	
	[Event(name="reply", 		type="maliboo.ftp.events.FTPCommandEvent")]
	[Event(name="command", 		type="maliboo.ftp.events.FTPCommandEvent")]
	[Event(name="error", 		type="flash.events.ErrorEvent")]
	[Event(name="complete", 	type="flash.events.Event")]
	
	public class CommandSequence extends EventDispatcher
	{
		private var _isRunning:Boolean;
		private var _lastCommand:FTPCommand;
		private var _doAbort:Boolean;
		private var commands:Array;
		protected var ftp:FTPCore;
		
		public function CommandSequence(ftp:FTPCore)
		{
			this._isRunning = false;
			this.commands = [];
			this.ftp = ftp;
		}
		
		public function get lastCommand():FTPCommand
		{
			return _lastCommand;
		}

		public function get isRunning():Boolean
		{
			return _isRunning;
		}

		public function prependCommand(comm:FTPCommand):FTPCommand
		{
			commands.unshift(comm);
			return comm;
		}
		
		public function addCommand(comm:FTPCommand):FTPCommand
		{
			commands.push(comm);
			return comm;
		}
		
		public function start():void
		{
			if (commands.length == 0 || isRunning)
				throw new IllegalOperationError("No commands or process is running!");
			_isRunning = true;
			sendNext();
		}
		
		public function abort():void
		{
			lastCommand.removeEventListener(FTPCommandEvent.REPLY, handleReply);
			_doAbort = true;
		}
		
		private function sendNext():void
		{
			if (commands.length == 0)
			{
				_isRunning = false;
				dispatchEvent(new Event(Event.COMPLETE));
				return;
			}
			_lastCommand = commands.shift() as FTPCommand;
			_lastCommand.addEventListener(FTPCommandEvent.REPLY, handleReply);
			ftp.internalSendCommand(_lastCommand);
		}
		
		private function handleReply(evt:FTPCommandEvent):void
		{
			(evt.target as IEventDispatcher).removeEventListener(evt.type, arguments.callee, evt.bubbles);
			if (_doAbort)
				return;
			dispatchEvent(evt);
			if (evt.reply.type & ReplyType.NEGATIVE)
				dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, "Reply code was negative: "+evt.reply.code));
			sendNext();
		}
	}
}