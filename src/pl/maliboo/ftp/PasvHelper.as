package pl.maliboo.ftp
{
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	
	import pl.maliboo.ftp.events.FTPCommandEvent;
	import pl.maliboo.ftp.rfc959.Commands;
	import pl.maliboo.ftp.rfc959.ReplyCodes;
	import pl.maliboo.ftp.utils.PassiveSocketInfo;

	public class PasvHelper
	{
		protected var ftp:FTPClient;
		protected var socket:FTPSocket;
		protected var commandSequence:CommandSequence;
		
		public function PasvHelper(ftp:FTPClient)
		{
			this.ftp = ftp;
		}
		
		public function start():void
		{
			restartSequence();
			commandSequence.start();
		}
		
		public function abort():void
		{
			commandSequence.abort();
			disposeSocket();
		}
		
		protected function restartSequence():void
		{
			commandSequence = new CommandSequence(ftp);
			appendCommand(new FTPCommand(Commands.TYPE_BINARY));
			appendCommand(new FTPCommand(Commands.PASV)).addEventListener(FTPCommandEvent.REPLY, handlePasvReply);
		}
		
		protected function disposeSocket():void
		{
			if (socket == null)
				return;
			socket.removeEventListener(Event.CONNECT, connectHandler);
			socket.removeEventListener(Event.CLOSE, closeHandler);
			socket.removeEventListener(ProgressEvent.PROGRESS, progressHandler);
			socket.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			try
			{
				socket.close();
			}
			catch (e:Error){};
			socket = null;
		}
		
		protected function prependCommand(comm:FTPCommand):FTPCommand
		{
			return commandSequence.prependCommand(comm);
		}
		
		protected function appendCommand(comm:FTPCommand):FTPCommand
		{
			return commandSequence.addCommand(comm);
		}
		
		protected function handlePasvReply(evt:FTPCommandEvent):void
		{
			if (evt.reply.code == ReplyCodes.ENTERING_PASV)
			{
				createDataSocket(PassiveSocketInfo.parseFromReply(evt.reply.rawBody));
			}
		}
		
		protected function createDataSocket(socketInfo:PassiveSocketInfo):void
		{
			disposeSocket();
			socket = ftp.openDataSocket(socketInfo);
			socket.addEventListener(Event.CONNECT, connectHandler);
			socket.addEventListener(Event.CLOSE, closeHandler);
			socket.addEventListener(ProgressEvent.PROGRESS, progressHandler);
			socket.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
		}
		
		protected function connectHandler(evt:Event):void
		{
			throw new IllegalOperationError("Must override in subclass!");
		}
		
		protected function closeHandler(evt:Event):void
		{
			throw new IllegalOperationError("Must override in subclass!");
		}
		
		protected function progressHandler(evt:ProgressEvent):void
		{
			throw new IllegalOperationError("Must override in subclass!");
		}
		
		protected function ioErrorHandler(evt:IOErrorEvent):void
		{
			throw new IllegalOperationError("Must override in subclass!");
		}
		
		protected function securityErrorHandler(evt:SecurityErrorEvent):void
		{
			throw new IllegalOperationError("Must override in subclass!");
		}
	}
}