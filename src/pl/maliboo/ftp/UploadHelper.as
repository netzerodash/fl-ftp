package pl.maliboo.ftp
{
	import flash.events.Event;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.setTimeout;
	
	import pl.maliboo.ftp.events.FTPCommandEvent;
	import pl.maliboo.ftp.events.FTPTransferEvent;
	import pl.maliboo.ftp.rfc959.ReplyCodes;
	import pl.maliboo.ftp.utils.PassiveSocketInfo;

	internal class UploadHelper
	{
		private var ftp:FTPClient;
		private var ftpFile:FTPFile;
		private var stream:IDataInput;
		private var bytesTotal:uint;
		private var chunkSize:uint;
		
		private var dataSocket:Socket;
		private var transferSeq:CommandSequence;
		private var position:uint;
		private var bufferDiff:int;
		private var outputBuffer:ByteArray;
		private var canFinalize:Boolean;
		
		public function UploadHelper(ftp:FTPClient, file:FTPFile, stream:IDataInput, chunkSize:uint)
		{
			this.ftp = ftp;
			this.ftpFile = file;
			this.stream = stream;
			this.chunkSize = chunkSize;
			this.bytesTotal = stream.bytesAvailable;
		}
		
		public function start():void
		{
			position = 0;
			bufferDiff = 0;
			outputBuffer = new ByteArray();
			canFinalize = false;
			transferSeq = new UploadInitSequence(ftp, ftpFile.name);
			transferSeq.addEventListener(FTPCommandEvent.REPLY, handleUploadStart);
			transferSeq.start();
		}
		
		public function abort():void
		{
			
		}
		
		private function closeCurrentSocket():void
		{
			ftp.addEventListener(FTPCommandEvent.REPLY, handleCloseReply);
			dataSocket.close();
		}
		
		private function handleCloseReply(evt:FTPCommandEvent):void
		{
			if (evt.reply.code == ReplyCodes.DATA_CONN_CLOSE)
			{
				ftp.removeEventListener(evt.type, handleCloseReply);
				if (canFinalize)
					ftp.dispatchEvent(new FTPTransferEvent(FTPTransferEvent.TRANSFER_COMPLETE, ftpFile, 
						bytesTotal, bytesTotal));
				else
					startAppe();
			}
			else
			{
				//TODO: What should I do?!
			}
		}
		
		private function startAppe():void
		{
			transferSeq = new UploadAppendSequence(ftp, ftpFile.name);
			transferSeq.addEventListener(FTPCommandEvent.REPLY, handleSizeGet);
			transferSeq.start();
		}
		
		private function writeAndFlush(stream:IDataInput, socket:Socket):void
		{
			var tempBuffer:ByteArray = new ByteArray();
			outputBuffer.position = outputBuffer.length - bufferDiff;
			//If buffer was emptied, dont't try to fill it wit 0!
			if (bufferDiff > 0)
				tempBuffer.writeBytes(outputBuffer, 0, bufferDiff);
			outputBuffer = tempBuffer;
			var maxChunk:uint = Math.min(chunkSize, stream.bytesAvailable);
			var additionalBufferBytes:int = maxChunk - outputBuffer.length;
			additionalBufferBytes = Math.max(0, additionalBufferBytes);
			//If we run out of bytes, but buffer is not empty, don't try read input stream!
			if (additionalBufferBytes > 0)
				stream.readBytes(outputBuffer, outputBuffer.length, additionalBufferBytes);
			position += outputBuffer.length;
			socket.writeBytes(outputBuffer);
			socket.flush();
		}
		
		private function handleSizeGet(evt:FTPCommandEvent):void
		{
			if (evt.reply.code == ReplyCodes.FILE_STATUS)
			{
				transferSeq.removeEventListener(FTPCommandEvent.REPLY, handleSizeGet);
				var sizeMatch:Array = evt.reply.rawBody.match(/^\d{1,3}\s+(\d{1,})$/);
				var serverSize:uint = parseInt(sizeMatch[1]) as uint;
				bufferDiff = position - serverSize;
				position = serverSize;
				if (position == bytesTotal)
				{
					canFinalize = true;
				}
				else
				{
					ftp.dispatchEvent(new FTPTransferEvent(FTPTransferEvent.TRANSFER_PROGRESS, ftpFile, 
						bytesTotal, position));
				}
				transferSeq.addEventListener(FTPCommandEvent.REPLY, handleAppeStart);
			}
			else
			{
				//TODO: What should I do!?
			}
		}
		
		private function handlePasvGet(evt:FTPCommandEvent):void
		{
			transferSeq.removeEventListener(FTPCommandEvent.REPLY, handleUploadStart);
			dataSocket = ftp.openDataSocket(PassiveSocketInfo.parseFromReply(evt.reply.rawBody));
			dataSocket.addEventListener(Event.CONNECT, handleUploadChunk);
		}
		
		private function handleUploadStart(evt:FTPCommandEvent):void
		{
			if (evt.reply.code == ReplyCodes.ENTERING_PASV)
			{
				transferSeq.removeEventListener(FTPCommandEvent.REPLY, handleUploadStart);
				handlePasvGet(evt);
				ftp.dispatchEvent(new FTPTransferEvent(FTPTransferEvent.TRANSFER_INIT, ftpFile));
			}
			else
			{
				//TODO: What should I do?
			}
		}
		
		private function handleAppeStart(evt:FTPCommandEvent):void
		{
			transferSeq.removeEventListener(FTPCommandEvent.REPLY, handleAppeStart);
			if (evt.reply.code == ReplyCodes.ENTERING_PASV)
				handlePasvGet(evt);
		}
		
		
		private function handleUploadChunk(evt:Event):void
		{
			
			if (!canFinalize)
				writeAndFlush(stream, dataSocket);
			setTimeout(closeCurrentSocket, 150);
		}
			
	}
}

import pl.maliboo.ftp.CommandSequence;
import pl.maliboo.ftp.FTPClient;
import pl.maliboo.ftp.FTPCommand;
import pl.maliboo.ftp.rfc959.Commands;
import pl.maliboo.ftp.events.FTPCommandEvent;
import pl.maliboo.ftp.utils.PassiveSocketInfo;



class UploadInitSequence extends CommandSequence
{
	public function UploadInitSequence(ftp:FTPClient, fileName:String)
	{
		super(ftp);
		addCommand(new FTPCommand(Commands.TYPE_BINARY));
		addCommand(new FTPCommand(Commands.PASV));
		addCommand(new FTPCommand(Commands.STOR, [fileName]));
	}
}

class UploadAppendSequence extends CommandSequence
{
	public function UploadAppendSequence(ftp:FTPClient, fileName:String)
	{
		super(ftp);
		addCommand(new FTPCommand(Commands.TYPE_BINARY)); //Is this necessary?	
		addCommand(new FTPCommand(Commands.SIZE, [fileName]));
		addCommand(new FTPCommand(Commands.PASV));
		addCommand(new FTPCommand(Commands.APPE, [fileName]));
	}
}