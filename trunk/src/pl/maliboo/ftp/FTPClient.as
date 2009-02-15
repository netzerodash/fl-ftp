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
	import pl.maliboo.ftp.helpers.UploadHelper;
	
	[Event(name="transferInit",		type="pl.maliboo.ftp.events.FTPTransferEvent")]
	[Event(name="transferError",	type="pl.maliboo.ftp.events.FTPTransferEvent")]
	[Event(name="transferProgress",	type="pl.maliboo.ftp.events.FTPTransferEvent")]
	[Event(name="transferComplete",	type="pl.maliboo.ftp.events.FTPTransferEvent")]
	
	[Event(name="list",				type="pl.maliboo.ftp.events.FTPListEvent")]
	
	public class FTPClient extends FTPCore
	{
		
		private var downStream:IDataOutput;
		private var upStream:IDataInput;
		private var progresBytes:uint;
		private var transferSeq:CommandSequence;
		private var ftpFile:FTPFile;
		
		private var transferLock:Boolean;
		
		private var uploadHelper:UploadHelper;
		
		private var uploadSize:uint = 50000;
		
		public function FTPClient(host:String=null, port:int=0)
		{
			transferLock = false;
			super(host, port);
		}
		
		override public function get inTransaction():Boolean
		{
			return super.inTransaction || transferLock;
		}
		
		/**
		 * Downloads a file from server to stream (ByteArray, FileStream). Stream must be valid IDataOutput implementor.
		 * 
		 */
		//Maybe it should return Boolean, or IEventListener?
		//TODO: implement async streams?!
		//TODO: implement client lock on transfer
		//TODO: move to class (like upload)
		public function downloadFile(file:FTPFile, stream:IDataOutput):void
		{
			if (inTransaction) //Maybe dataConnOpen?
				throw new IllegalOperationError("Data connection allready open!");
			//transferLock = true;
			downStream = stream;
			ftpFile = file;
			transferSeq = new DownloadSequence(this, ftpFile.name);
			transferSeq.addEventListener(FTPCommandEvent.REPLY, handleDownloadStart);
			transferSeq.start();
		}
		
		
		/**
		 * Uploads a stream (ByteArray, FileStream) to server. Stream must be valid IDataInput implementor.
		 * 
		 */ 
		/* 
		This is some kind of tricky&dirty hack. Due to Adobe ignorance we don't have
		ANY control over output progress, like in FileStream OutputProgress.OUTPUT_PROGRESS
		https://bugs.adobe.com/jira/browse/FP-6
		So we have to pretend that. Unfortunately server MUST support PASV and APPE commands.
		Nowadays I don't know any FTP server that don't support that:)
		Each "iteration" is bunch of:
		TYPE I
		SIZE [file]
		PASV
		APPE
		operations, so it takes some time to end this sequence. Uplod progress (Socket::flush)
		is "invisible" for API. Each chunk upload is discrete. More: see UploadHelper clas
		*/
		//TODO: implement client lock on transfer
		public function uploadFile(file:FTPFile, stream:IDataInput):void
		{
			if (inTransaction) //A moze dataConnOpen?
				throw new IllegalOperationError("Data connection allready open!");
			//transferLock = true;
			upStream = stream;
			ftpFile = file;
			uploadHelper = new UploadHelper(this, file, stream, uploadSize);
			uploadHelper.start();
		}
		
		public function cancelTransfer():void
		{
			//TODO: impl
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


