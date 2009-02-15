package pl.maliboo.ftp
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import pl.maliboo.ftp.events.FTPCommandEvent;
	import pl.maliboo.ftp.utils.PassiveSocketInfo;
	
	[Event(name="connect", 			type="flash.events.Event")]
	[Event(name="close", 			type="flash.events.Event")]
	[Event(name="ioError",			type="flash.events.IOErrorEvent")]
	[Event(name="securityError", 	type="flash.events.SecurityErrorEvent")]
	
	[Event(name="reply", 		type="maliboo.ftp.events.FTPCommandEvent")]
	[Event(name="command", 		type="maliboo.ftp.events.FTPCommandEvent")]
	
	/**
	 * FTP core class. Intentionally levae internal.
	 * 
	 * More info about FTP protocol: http://www.faqs.org/rfcs/rfc959.html
	 */ 
	internal class FTPCore extends EventDispatcher
	{
		protected static const CRLF:String = "\r\n";
		private static const MIN_TIMEOUT:uint = 250;
		
		private var _host:String;
		private var _port:int;
		private var _timeout:uint;
		private var timeoutInterval:uint;
		
		protected var controlSocket:FTPSocket;
		protected var dataSocket:FTPSocket;
		private var inputStringBuffer:String;
		private var inputStringBufferHistory:String;
		private var bajabongo:Array = [];
		
		private var _lastCommand:FTPCommand;
		private var _lastReply:FTPReply;
		
		private var awaitingCommands:Array;
		
		public function FTPCore(host:String=null, port:int=0)
		{
			_timeout = 5000;
			if (host != null)
				connect(host, port);
		}
		
		public function get timeout():uint
		{
			return _timeout;
		}

		public function set timeout(value:uint):void
		{
			_timeout = Math.max(value, MIN_TIMEOUT);
		}

		public function get inTransaction():Boolean
		{
			return pendingCommandsNum>0 || dataConnectionOpen;
		}
		
		public function get pendingCommandsNum():uint
		{
			return awaitingCommands.length;
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
			releaseControlSocket();
			_host = host;
			_port = port;
			awaitingCommands = [null];
			inputStringBuffer = new String("");
			inputStringBufferHistory = new String("");
			controlSocket = new FTPSocket();
			controlSocket.addEventListener(Event.CONNECT, handleConnect);
			controlSocket.addEventListener(Event.CLOSE, handleClose);
			controlSocket.addEventListener(IOErrorEvent.IO_ERROR, handleIOError);
			controlSocket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleSecurityError);
			controlSocket.addEventListener(ProgressEvent.SOCKET_DATA, handleSocketData);
			controlSocket.connect(host, port);
		}
		
		//TODO: Should be protected??
		/*protected*/public function openDataSocket(info:PassiveSocketInfo):FTPSocket
		{
			try
			{
				dataSocket.close();
			}
			catch(e:Error){}
			dataSocket = new FTPSocket();
			awaitingCommands.push(null); //After succ transfer we're awaiting for additional reply
			
			//BUG: Watch for context! See: http://blog.vandenoostende.com/?p=68
			var contextKeeper:Function = function ():void
			{
				dataSocket.connect(info.host, info.port);
			}
			setTimeout(contextKeeper, 10);
			return dataSocket;
		}
		
		public function close():void
		{
			releaseControlSocket();
		}
		
		public function get connected():Boolean
		{
			return controlSocket.connected;
		}
		
		private function get dataConnectionOpen():Boolean
		{
			return dataSocket && dataSocket.connected;
		}
		
		public function sendCommand(command:String, ...rest):FTPCommand
		{
			return internalSendCommand(new FTPCommand(command, rest));
		}
		
		internal function internalSendCommand(command:FTPCommand):FTPCommand
		{
			clearTimeout(timeoutInterval);
			_lastCommand = command;
			awaitingCommands.push(command);
			controlSocket.writeUTFBytes(command.rawBody+CRLF); //Should be writeMultiBytes?
			controlSocket.flush();
			dispatchEvent(new FTPCommandEvent(FTPCommandEvent.COMMAND, null, command));
			timeoutInterval = setTimeout(fireTimeout, timeout);
			
			//setTimeout(controlSocket.flush, 10);
			return command;
		}
		
		private function releaseControlSocket():void
		{
			clearTimeout(timeoutInterval);
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
			
			try
			{
				dataSocket.close();
			}
			catch (e:Error){}
			dataSocket = null;
			
			_lastCommand = null;
			_lastReply = null;
			awaitingCommands = null;
			inputStringBuffer = null;
			inputStringBufferHistory = null;
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
			//dispatchEvent(evt);
			//dispatchEvent(new SecurityErrorEvent(SecurityErrorEvent.SECURITY_ERROR));
			/*
			Dziwna sprawa, po pasv>retr na ten socket przychodza dane z pasv?? WTF?!
			*/
		}
		
		private function handleSocketData(evt:ProgressEvent):void
		{
			//Moze jednak to powinno byc po poprawnym reply?!
			//Albo jeszcze lepiej, tutaj podbijamy timout, a ostatecznie czyscimy dopiero po komendzie
			clearTimeout(timeoutInterval);
			inputStringBuffer += controlSocket.readUTFBytes(controlSocket.bytesAvailable);
			parseBuffer();
		}

		//TODO: trzeba rozbic input buffer na Reply! Inaczej potrafi zbic kilka w jedno!
		//Trzeba czytac liniami, ale jak sie zabezpieczyc przed tym, 
		//ze ostatnia jeszcze sie nie skonczyla?
		private function parseBuffer():void
		{
			var reply:FTPReply;
			do
			{
				var rx:RegExp = /^\d{3}[^-].*$/gm;
				var inputLines:Array = rx.exec(inputStringBuffer);
				try
				{
					var replyString:String = inputStringBuffer.substr(0, rx.lastIndex);
					reply = new FTPReply(replyString);
				}
				catch(e:Error)
				{
					reply = null;
				}
				finally
				{
					if (reply)
					{
						inputStringBufferHistory += inputStringBuffer;
						inputStringBuffer = inputStringBuffer.slice(rx.lastIndex).replace(/^\s+/gm, "");
						_lastReply = reply;
						var comm:FTPCommand = awaitingCommands.shift() as FTPCommand;
						dispatchEvent(new FTPCommandEvent(FTPCommandEvent.REPLY, reply));
						if (comm != null)
							comm.setReply(reply);
					}
				}
			}
			while(reply != null && inputStringBuffer.length)
		}
		
		private function fireTimeout():void
		{
			close();
			dispatchEvent(new SecurityErrorEvent(SecurityErrorEvent.SECURITY_ERROR, false, false, 
				"Socket timeout: "+timeout+"!"));
		}
	}
}