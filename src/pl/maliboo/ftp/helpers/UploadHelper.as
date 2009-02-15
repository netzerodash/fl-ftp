package pl.maliboo.ftp.helpers
{
	import flash.errors.IllegalOperationError;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.setTimeout;
	
	import pl.maliboo.ftp.FTPClient;
	import pl.maliboo.ftp.FTPCommand;
	import pl.maliboo.ftp.FTPFile;
	import pl.maliboo.ftp.FTPReply;
	import pl.maliboo.ftp.PasvHelper;
	import pl.maliboo.ftp.events.FTPCommandEvent;
	import pl.maliboo.ftp.events.FTPTransferEvent;
	import pl.maliboo.ftp.rfc959.Commands;
	import pl.maliboo.ftp.rfc959.ReplyCodes;
	
	public class UploadHelper extends PasvHelper
	{
		private var file:FTPFile;
		private var stream:IDataInput;
		
		private var bytesTotal:uint;
		private var chunkSize:uint;
		private var position:uint;
		private var bufferDiff:int;
		private var outputBuffer:ByteArray;
		private var canFinalize:Boolean;
		
		public function UploadHelper(ftp:FTPClient, file:FTPFile, stream:IDataInput, chunkSize:uint)
		{
			super(ftp);
			this.file = file;
			this.stream = stream;
			this.bytesTotal = stream.bytesAvailable;
			this.chunkSize = chunkSize;
		}
		
		
		override protected function restartSequence():void
		{
			super.restartSequence();
			prependCommand(new FTPCommand(Commands.SIZE, [file.nativePath]));
			//TYPE_BINARY
			//PASV
			appendCommand(new FTPCommand(Commands.APPE, [file.nativePath]));
			commandSequence.addEventListener(FTPCommandEvent.REPLY, handleSequenceReply);
			commandSequence.addEventListener(ErrorEvent.ERROR, handleError);
		}
		
		override public function start():void
		{
			position = 0;
			bufferDiff = 0;
			outputBuffer = new ByteArray();
			canFinalize = false;
			super.start();
			ftp.dispatchEvent(new FTPTransferEvent(FTPTransferEvent.TRANSFER_INIT, file));
		}
		
		override protected function connectHandler(evt:Event):void
		{
			if (!canFinalize)
				writeAndFlush();
			setTimeout(closeCurrentSocket, 150);
		}
		
		override protected function closeHandler(evt:Event):void
		{
			//throw new IllegalOperationError("Must override in subclass!");
		}
		
		override protected function progressHandler(evt:ProgressEvent):void
		{
			//throw new IllegalOperationError("Must override in subclass!");
		}
		
		override protected function ioErrorHandler(evt:IOErrorEvent):void
		{
			throw new IllegalOperationError("Must override in subclass!");
		}
		
		override protected function securityErrorHandler(evt:SecurityErrorEvent):void
		{
			throw new IllegalOperationError("Must override in subclass!");
		}
		
		private function loopSequence():void
		{
			restartSequence();
			commandSequence.start();
		}
		
		private function writeAndFlush():void
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
		
		private function handleSizeGet(reply:FTPReply):void
		{
			var sizeMatch:Array = reply.rawBody.match(/^\d{1,3}\s+(\d{1,})$/);
			var serverSize:uint = parseInt(sizeMatch[1]) as uint;
			bufferDiff = position - serverSize;
			position = serverSize;
			if (position == bytesTotal)
			{
				canFinalize = true;
			}
			else
			{
				ftp.dispatchEvent(new FTPTransferEvent(FTPTransferEvent.TRANSFER_PROGRESS, file, 
					bytesTotal, position));
			}
		}
			
		private function closeCurrentSocket():void
		{
			ftp.addEventListener(FTPCommandEvent.REPLY, handleCloseReply);
			socket.close();
		}
			
		private function handleCloseReply(evt:FTPCommandEvent):void
		{
			if (evt.reply.code == ReplyCodes.DATA_CONN_CLOSE)
			{
				ftp.removeEventListener(evt.type, handleCloseReply);
				if (canFinalize)
					ftp.dispatchEvent(new FTPTransferEvent(FTPTransferEvent.TRANSFER_COMPLETE, file, 
						bytesTotal, bytesTotal));
				else
					loopSequence();
			}
			else
			{
				//TODO: What should I do?!
			}
		}
		
		
		private function handleSequenceReply(evt:FTPCommandEvent):void
		{
			switch (evt.reply.code)
			{
				case ReplyCodes.FILE_STATUS:
					handleSizeGet(evt.reply); break;
				case ReplyCodes.ENTERING_PASV:
				case ReplyCodes.COMMAND_OK:
				//case ReplyCodes.DATA_CONN_CLOSE:
					break;
				default:
					trace("Hmmm, what to do with: "+evt.reply.code);
			}
		}
		
		private function handleError(evt:ErrorEvent):void
		{
			
		}
	}
}