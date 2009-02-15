package pl.maliboo.ftp.utils
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	
	import pl.maliboo.ftp.FTPClient;
	import pl.maliboo.ftp.FTPCommand;
	import pl.maliboo.ftp.events.FTPCommandEvent;

	public class ConsoleListener
	{
		private var ftpConnection:FTPClient;
		
		public function ConsoleListener(ftpConn:FTPClient)
		{
			ftpConnection = ftpConn;
			ftpConnection.addEventListener(Event.CONNECT, handleConnect);
			ftpConnection.addEventListener(Event.CLOSE, handleClose);
			ftpConnection.addEventListener(FTPCommandEvent.COMMAND, handleCommand);
			ftpConnection.addEventListener(FTPCommandEvent.REPLY, handleReply);
			ftpConnection.addEventListener(IOErrorEvent.IO_ERROR, handleIOError);
			ftpConnection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleSecurity);
		}
		
		public function dispose():void
		{
			ftpConnection.removeEventListener(Event.CONNECT, handleConnect);
			ftpConnection.removeEventListener(Event.CLOSE, handleClose);
			ftpConnection.removeEventListener(FTPCommandEvent.COMMAND, handleCommand);
			ftpConnection.removeEventListener(FTPCommandEvent.REPLY, handleReply);
			ftpConnection.removeEventListener(IOErrorEvent.IO_ERROR, handleIOError);
			ftpConnection.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, handleSecurity);
		}
		
		
		private function handleConnect(evt:Event):void
		{
			trace("Connected with", ftpConnection.host, ftpConnection.port);
		}
		
		private function handleClose(evt:Event):void
		{
			trace("Closed connection", ftpConnection.host, ftpConnection.port);
		}
		
		private function handleCommand(evt:FTPCommandEvent):void
		{
			trace("$>", evt.command.toString());
			//evt.command.addEventListener(FTPCommandEvent.REPLY, handleCommandReply);
		}
		
		private function handleReply(evt:FTPCommandEvent):void
		{
			//trace("Reply incoming");
			trace(evt.reply.toString());
			trace("-------------------------");
		}
		
		private function handleIOError(evt:IOErrorEvent):void
		{
			trace("IOError");
		}
		
		private function handleSecurity(evt:SecurityErrorEvent):void
		{
			trace(evt);
		}
		
		private function handleCommandReply(evt:FTPCommandEvent):void
		{
			trace("$>", (evt.target as FTPCommand).toString());
			trace(evt.reply.toString());
			trace("-------------------------");
		}

	}
}