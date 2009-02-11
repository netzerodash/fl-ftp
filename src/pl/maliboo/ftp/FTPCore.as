package pl.maliboo.ftp
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.utils.ByteArray;
	
	import pl.maliboo.ftp.events.FTPCommandEvent;
	
	[Event(name="connect", 			type="flash.events.Event")]
	[Event(name="close", 			type="flash.events.Event")]
	[Event(name="ioError",			type="flash.events.IOErrorEvent")]
	[Event(name="securityError", 	type="flash.events.SecurityErrorEvent")]
	
	[Event(name="response", 		type="maliboo.ftp.events.FTPCommandEvent")]
	
	public class FTPCore extends EventDispatcher
	{
		private var _host:String;
		private var _port:int;
		
		private var controlSocket:FTPSocket;
		private var inputBuffer:ByteArray;
		
		private var _lastCommand:FTPCommand;
		private var _lastResponse:FTPResponse;
		
		public function FTPCore(host:String=null, port:int=0)
		{
			if (host != null)
				connect(host, port);
		}
		
		public function get lastResponse():FTPResponse
		{
			return _lastResponse.clone();
		}

		public function get lastCommand():FTPCommand
		{
			return _lastCommand.clone();
		}

		public function get host():String
		{
			return _host;
		}
		
		public function get port():int
		{
			return _port;
		}

		public function connect(host:String, port:int=21):void
		{
			_host = host;
			_port = port;
			inputBuffer = new ByteArray();
			releaseControlSocket();
			controlSocket = new FTPSocket();
			controlSocket.addEventListener(Event.CONNECT, handleConnect);
			controlSocket.addEventListener(Event.CLOSE, handleClose);
			controlSocket.addEventListener(IOErrorEvent.IO_ERROR, handleIOError);
			controlSocket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleSecurityError);
			controlSocket.addEventListener(ProgressEvent.SOCKET_DATA, handleSocketData);
			controlSocket.connect(host, port);
		}
		
		public function close():void
		{
			releaseControlSocket();
		}
		
		public function get connected():Boolean
		{
			return controlSocket.connected;
		}
		
		public function sendCommand(command:String, ...rest):void
		{
			internalSendCommand(new FTPCommand(command, rest));
		}
		
		protected function internalSendCommand(command:FTPCommand):void
		{
			//TODO:impl: command stack???
			_lastCommand = command;
			controlSocket.writeUTFBytes(command.rawBody+"\n");
			controlSocket.flush();
			dispatchEvent(new FTPCommandEvent(FTPCommandEvent.COMMAND, null, command));
		}
		
		private function releaseControlSocket():void
		{
			if (controlSocket == null)
				return;
			controlSocket.removeEventListener(Event.CONNECT, handleConnect);
			controlSocket.removeEventListener(Event.CLOSE, handleClose);
			controlSocket.removeEventListener(IOErrorEvent.IO_ERROR, handleIOError);
			controlSocket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, handleSecurityError);
			controlSocket.removeEventListener(ProgressEvent.SOCKET_DATA, handleSocketData);
			try
			{
				controlSocket.close();
			}
			catch (e:Error){}
			controlSocket = null;
		}
		
		private function handleConnect(evt:Event):void
		{
			dispatchEvent(new Event(Event.CONNECT));
		}
		
		private function handleClose(evt:Event):void
		{
			dispatchEvent(new Event(Event.CLOSE));
		}
		
		private function handleIOError(evt:IOErrorEvent):void
		{
			dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR));
		}
		
		private function handleSecurityError(evt:SecurityErrorEvent):void
		{
			dispatchEvent(new SecurityErrorEvent(SecurityErrorEvent.SECURITY_ERROR));
		}
		
		private function handleSocketData(evt:ProgressEvent):void
		{
			controlSocket.readBytes(inputBuffer);
			parseBuffer();
		}

		private function parseBuffer():void
		{
			inputBuffer.position = 0;
			var responseString:String = inputBuffer.readUTFBytes(inputBuffer.bytesAvailable);
			var response:FTPResponse;
			try
			{
				response = new FTPResponse(responseString);
			}
			catch(e:Error)
			{
			}
			finally
			{
				if (response)
				{
					inputBuffer.clear();
					_lastResponse = response;
					dispatchEvent(new FTPCommandEvent(FTPCommandEvent.RESPONSE, response));
				}
			}
		}
		
	}
}