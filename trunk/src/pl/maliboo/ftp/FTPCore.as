package pl.maliboo.ftp
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.utils.ByteArray;
	
	import pl.maliboo.ftp.events.FTPCommandEvent;
	import pl.maliboo.ftp.rfc959.ReplyType;
	
	[Event(name="connect", 			type="flash.events.Event")]
	[Event(name="close", 			type="flash.events.Event")]
	[Event(name="ioError",			type="flash.events.IOErrorEvent")]
	[Event(name="securityError", 	type="flash.events.SecurityErrorEvent")]
	
	[Event(name="reply", 		type="maliboo.ftp.events.FTPCommandEvent")]
	[Event(name="command", 		type="maliboo.ftp.events.FTPCommandEvent")]
	
	public class FTPCore extends EventDispatcher
	{
		private var _host:String;
		private var _port:int;
		
		private var controlSocket:FTPSocket;
		private var inputBuffer:ByteArray;
		
		private var _lastCommand:FTPCommand;
		private var _lastReply:FTPReply;
		
		private var awaitingCommands:Array;
		private var commandQueue:Array;
		
		public function FTPCore(host:String=null, port:int=0)
		{
			if (host != null)
				connect(host, port);
		}
		
		private function get locked():Boolean
		{
			if (lastReply)
				return Boolean(lastReply.type & ReplyType.CONTINUABLE);
			return false;
		}

		public function get lastReply():FTPReply
		{
			return _lastReply.clone();
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
			awaitingCommands = [null];
			commandQueue = [];
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
		
		public function sendCommand(command:String, ...rest):FTPCommand
		{
			return internalSendCommand(new FTPCommand(command, rest));
		}
		
		protected function internalSendCommand(command:FTPCommand):FTPCommand
		{
			//TODO:impl: command stack???
			_lastCommand = command;
			awaitingCommands.push(command);
			controlSocket.writeUTFBytes(command.rawBody+"\n");
			controlSocket.flush();
			//dispatchEvent(new FTPCommandEvent(FTPCommandEvent.COMMAND, null, command));
			return command;
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
			dispatchEvent(evt);
			//dispatchEvent(new Event(Event.CONNECT));
		}
		
		private function handleClose(evt:Event):void
		{
			dispatchEvent(evt);
			//dispatchEvent(new Event(Event.CLOSE));
		}
		
		private function handleIOError(evt:IOErrorEvent):void
		{
			dispatchEvent(evt);
			//dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR));
		}
		
		private function handleSecurityError(evt:SecurityErrorEvent):void
		{
			dispatchEvent(evt);
			//dispatchEvent(new SecurityErrorEvent(SecurityErrorEvent.SECURITY_ERROR));
		}
		
		private function handleSocketData(evt:ProgressEvent):void
		{
			controlSocket.readBytes(inputBuffer);
			parseBuffer();
		}

		//TODO: trzeba rozbic input buffer na Reply! Inaczej potrafi zbic kilka w jedno!
		//Trzeba czytac liniami, ale jak sie zabezpieczyc przed tym, 
		//ze ostatnia jeszcze sie nie skonczyla?
		private function parseBuffer():void
		{
			inputBuffer.position = 0;
			var replyString:String = inputBuffer.readUTFBytes(inputBuffer.bytesAvailable);
			var reply:FTPReply;
			try
			{
				reply = new FTPReply(replyString);
			}
			catch(e:Error)
			{
			}
			finally
			{
				if (reply)
				{
					inputBuffer.clear();
					_lastReply = reply;
					var comm:FTPCommand = awaitingCommands.shift() as FTPCommand;
					if (comm != null)
						comm.reply = reply;
					dispatchEvent(new FTPCommandEvent(FTPCommandEvent.REPLY, reply));
				}
			}
		}
		
	}
}