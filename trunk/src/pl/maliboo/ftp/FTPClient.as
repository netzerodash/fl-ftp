package pl.maliboo.ftp
{
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import pl.maliboo.ftp.events.FTPCommandEvent;
	import pl.maliboo.ftp.events.FTPTransferEvent;
	
	[Event(name="ioError",	type="flash.events.IOErrorEvent")]
	[Event(name="progress",	type="flash.events.ProgressEvent")]
	[Event(name="complete",	type="flash.events.Event")]
	[Event(name="init",		type="flash.events.Event")]
	
	[Event(name="transferInit",		type="pl.maliboo.ftp.events.FTPTransferEvent")]
	[Event(name="transferError",	type="pl.maliboo.ftp.events.FTPTransferEvent")]
	[Event(name="transferProgress",	type="pl.maliboo.ftp.events.FTPTransferEvent")]
	[Event(name="transferComplete",	type="pl.maliboo.ftp.events.FTPTransferEvent")]
	
	public class FTPClient extends FTPCore
	{
		
		private var downStream:IDataOutput;
		private var upStream:IDataInput;
		private var progresBytes:uint;
		private var transferSeq:CommandSequence;
		private var ftpFile:FTPFile;
		
		private var uploadHelper:UploadHelper;
		
		private var uploadSize:uint = 50000;
		
		public function FTPClient(host:String=null, port:int=0)
		{
			super(host, port);
		}
		
		//Moze powinno cos zwracac? Jakiegos EventListenera?
		public function downloadFile(file:FTPFile, stream:IDataOutput):void
		{
			if (inTransaction) //A moze dataConnOpen?
				throw new IllegalOperationError("Data connection allready open!");
			downStream = stream;
			ftpFile = file;
			transferSeq = new DownloadSequence(this, ftpFile.name);
			transferSeq.addEventListener(FTPCommandEvent.REPLY, handleDownloadStart);
			transferSeq.start();
		}
		
		public function uploadFile(file:FTPFile, stream:IDataInput):void
		{
			if (inTransaction) //A moze dataConnOpen?
				throw new IllegalOperationError("Data connection allready open!");
			upStream = stream;
			ftpFile = file;
			uploadHelper = new UploadHelper(this, file, stream, uploadSize);
			uploadHelper.start();
		}
		
		private function writeToStream(socket:Socket, stream:IDataOutput):void
		{
			progresBytes += socket.bytesAvailable;
			var inputBuffer:ByteArray = new ByteArray();
			socket.readBytes(inputBuffer);
			stream.writeBytes(inputBuffer);
		}
		
		private function handleDownloadStart(evt:FTPCommandEvent):void
		{
			transferSeq.removeEventListener(evt.type, handleDownloadStart);
			dataSocket.addEventListener(ProgressEvent.SOCKET_DATA, handleDownloadProgress);
			dataSocket.addEventListener(Event.CLOSE, handleDownloadComplete);
			progresBytes = 0;
			dispatchEvent(new FTPTransferEvent(FTPTransferEvent.TRANSFER_INIT, ftpFile));
		}
		
		private function handleDownloadProgress(evt:ProgressEvent):void
		{
			writeToStream(dataSocket, downStream);
			trace("Progress: "+progresBytes);
			dispatchEvent(new FTPTransferEvent(FTPTransferEvent.TRANSFER_PROGRESS, ftpFile, 0, progresBytes));
		}
		
		private function handleDownloadComplete(evt:Event):void
		{
			trace("Complete "+dataSocket.bytesAvailable);
			writeToStream(dataSocket, downStream);
			dispatchEvent(new FTPTransferEvent(FTPTransferEvent.TRANSFER_COMPLETE, ftpFile, 0, progresBytes));
		}
	}
}	
	
	
import pl.maliboo.ftp.CommandSequence;
import pl.maliboo.ftp.FTPClient;
import pl.maliboo.ftp.FTPCommand;
import pl.maliboo.ftp.rfc959.Commands;
import pl.maliboo.ftp.events.FTPCommandEvent;
import pl.maliboo.ftp.utils.PassiveSocketInfo;



class DownloadSequence extends CommandSequence
{
	public function DownloadSequence(ftp:FTPClient, fileName:String)
	{
		super(ftp);
		addCommand(new FTPCommand(Commands.PASV)).addEventListener(FTPCommandEvent.REPLY, openDataSocket);
		addCommand(new FTPCommand(Commands.RETR, [fileName]));
	}
	
	private function openDataSocket(evt:FTPCommandEvent):void
	{
		ftp.openDataSocket(PassiveSocketInfo.parseFromReply(evt.reply.rawBody));
	}
}

