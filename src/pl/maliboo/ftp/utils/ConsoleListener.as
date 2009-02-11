package pl.maliboo.ftp.utils
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	
	import pl.maliboo.ftp.FTPCore;
	import pl.maliboo.ftp.events.FTPCommandEvent;
	import pl.maliboo.ftp.rfc959.Commands;
	import pl.maliboo.ftp.rfc959.ReplyCodes;

	public class ConsoleListener
	{
		private var ftpConnection:FTPCore;
		
		public function ConsoleListener(ftpConn:FTPCore)
		{
			ftpConnection = ftpConn;
			ftpConnection.addEventListener(Event.CONNECT, handleConnect);
			ftpConnection.addEventListener(Event.CLOSE, handleClose);
			ftpConnection.addEventListener(FTPCommandEvent.COMMAND, handleCommand);
			ftpConnection.addEventListener(FTPCommandEvent.RESPONSE, handleResponse);
			ftpConnection.addEventListener(IOErrorEvent.IO_ERROR, handleIOError);
			ftpConnection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleSecurity);
		}
		
		public function dispose():void
		{
			ftpConnection.removeEventListener(Event.CONNECT, handleConnect);
			ftpConnection.removeEventListener(Event.CLOSE, handleClose);
			ftpConnection.removeEventListener(FTPCommandEvent.COMMAND, handleCommand);
			ftpConnection.removeEventListener(FTPCommandEvent.RESPONSE, handleResponse);
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
			trace(">"+evt.command.rawBody);
		}
		
		private function handleResponse(evt:FTPCommandEvent):void
		{
			//trace("Response");
			trace(evt.response.rawBody);
			switch (evt.response.code)
			{
				case ReplyCodes.SERVICE_READY:
					ftpConnection.sendCommand(Commands.USER, "");
					ftpConnection.sendCommand(Commands.PASS, "");
					ftpConnection.sendCommand(Commands.SYST);
					ftpConnection.sendCommand(Commands.FEAT);
					ftpConnection.sendCommand(Commands.HELP);										
					ftpConnection.sendCommand(Commands.TYPE, "I");
					ftpConnection.sendCommand(Commands.LIST);
					break;
				case ReplyCodes.USER_OK:
					//ftpConnection.sendCommand(Commands.PASS, "flftp");
					break;
				case ReplyCodes.LOGGED_IN:
					break;
				case ReplyCodes.COMMAND_OK:
					break;
				default:
					trace("What to do with", evt.response.code);
			}
		}
		
		private function handleIOError(evt:IOErrorEvent):void
		{
			trace("IOError");
		}
		
		private function handleSecurity(evt:SecurityErrorEvent):void
		{
			trace("SecError");
		}

	}
}